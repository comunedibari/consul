require 'active_support/core_ext/digest/uuid'

class UserInvestmentsController < ApplicationController
  include CustomUrlsHelper
  include FeatureFlags
  include FlagActions

  #before_action :authenticate_user!, only: :create
  before_action :load_data, only: [:show] #, :delete_investment]

  load_and_authorize_resource :crowdfunding
  load_and_authorize_resource :user_investment, through: :crowdfunding

  before_action :verified_min_investment, only: [:create]
  respond_to :html, :js

  def verified_min_investment
    @crowdfunding = Crowdfunding.where(id: user_investment_params[:crowdfunding_id]).first
  end

  ###################################################################
  # ACTION DISABILITATA, PER ABILITARLA INSERIRLA ANCHE NELLE ROTTE #
  ###################################################################
  # def delete_investment
  #   i_id = params[:id]
  #   @user_investment = UserInvestment.where(id: i_id).first
  #   @user_investment.update_attribute(:status, UserInvestment.statuses[:rejected])
  #   #UserInvestment.hide @user_investment
  #   block_user_investment
  #   @crowdfunding = Crowdfunding.find_by(id: @user_investment.crowdfunding_id)
  #   redirect_to crowdfunding_path(@crowdfunding.id)
  # end

  def block_user_investment
    @user_investment.block
  end

  def show
  end

  def new
    if current_user
      if current_user.is_spid?
        return @user_investment = UserInvestment.new(
            investor: current_user.username,
            email: current_user.email,
            fiscal_code: current_user.cod_fiscale
        )
      end

      if current_user.is_social?
        return @user_investment = UserInvestment.new(
            investor: current_user.username,
            email: current_user.email
        )
      end

    end
  end

  def create
    if user_investment_params[:value_investements] == nil
      flash[:alert] = I18n.t('verification.residence.new.error_investment_not_null')
      # redirect_to :back
      render :new and return
    elsif user_investment_params[:value_investements].to_f < @crowdfunding.min_price
      flash[:alert] = I18n.t('verification.residence.new.error_investment_too_low')
      # redirect_to :back
      render :new and return
    end

    # Prelevo dati dal backend
    @user_investment = UserInvestment.new(
        user_investment_params.merge(load_current_data).merge(status: UserInvestment.statuses[:pending]).merge(source: 'Bari Partecipa')
    )

    # Triggeriamo manualmente la validazione per assicurarci che a mypay arrivi un
    # Codice Fiscale valido
    unless @user_investment.valid?
      render :new and return
    end
    #appplico un uppercase sul codice fiscale per salvarlo correttamente
    @user_investment.fiscal_code = @user_investment.fiscal_code.upcase

    # Chiamo il portale pagamenti esterni e ricavo identificativoPagamento
    mypay_json_response = mypay_init(user_investment_params)

    if mypay_json_response["esito"] == 'KO' or mypay_json_response["identificativoPagamento"] == ''
      flash[:alert] = t('crowdfundings.user_investments.errors.payment_system_error')
      redirect_to :back
      return
    end

    # Impostiamo nello user investment l'identificativo pagamento ricevuto dal sistema di pagamento
    @user_investment.payment_id = mypay_json_response["identificativoPagamento"]
    @user_investment.credit_id = mypay_json_response["credit_id"]

    if @user_investment.save

      if Time.current > @crowdfunding.end_date
        @user_investment.update_attribute(:status, UserInvestment.statuses[:rejected])
        flash[:alert] = t('crowdfundings.user_investments.errors.payment_system_error')
        redirect_to crowdfunding_path(@crowdfunding)
        return
      end

      # Tutto ok, posso fare il redirect alla url fornita dal sistema di pagamento
      # Lo user investment a questo punto sarà in stato "pending"
      redirect_to mypay_json_response["redirectUrl"]

    else
      flash[:alert] = I18n.t('verification.residence.new.error_fiels')
      render :new
    end

  end

  def index
  end

  def share
    if Setting['user_investment_improvement_path', User.pon_id].present?
      @user_investment_improvement_path = Setting['user_investment_improvement_path', User.pon_id]
    end
  end

  private

  ##
  # Generazione credit id in maniera randomica, utilizzando una combinazione di:
  # prefisso identificativo credito preso dai settings
  # 32 bit esadecimali generati in maniera casuale dalla classe SecureRandom
  # Unix time
  #
  # uuid_v5 alla base genera un uuid in maniera deterministica facendo l'hash dei parametri forniti
  def generate_credit_id
    uuid = Digest::UUID.uuid_v5(Setting['crowdfunding.identificativoCredito', User.pon_id], SecureRandom.hex(32) + Time.now.to_i.to_s)
  end

  def user_investment_params
    params.require(:user_investment).permit(:investor, :email, :fiscal_code, :note, :created_at, :value_investements, :crowdfunding_id, :user_id, :check, :visible, :refound_info, :reward_info, crowdfundings_attributes: [:id])
  end

  def mypay_init(user_investment_params)

    # Ricavo il crowdfunding padre:
    crowdfunding = Crowdfunding.find_by(id: user_investment_params[:crowdfunding_id])

    # genero identificativoCredito
    credit_id = Setting['crowdfunding.identificativoCredito', User.pon_id] + '-' + generate_credit_id
    causale = crowdfunding.title.upcase.gsub!(/[^0-9A-Za-z]/, ' ').nil? ? crowdfunding.title.upcase : crowdfunding.title.upcase.gsub!(/[^0-9A-Za-z]/, ' ')
    if Rails.application.config.environment_set != 'prod'
      payment_data = {
          :callBackUrlOrganizzazione => Rails.application.config.root_path + payment_outcome_crowdfunding_path(crowdfunding.id),
          :callBackEndpointWsUrlOrganizzazione =>Rails.application.config.base_url + Rails.application.config.wsdl_path, # TODO: poi la root andrà cambiata finiti i test
          :causale => Rails.application.config.prefix_causale + causale.split(' ').join('-').first(100).to_s,
          :codiceCategoriaServizio => Setting['crowdfunding.codiceCategoriaServizio', User.pon_id],
          :codiceOrganizzazione => Rails.application.config.codIpa ,
          :denominazioneCliente => user_investment_params[:investor], # user_investment.user.username
          :descrizioneServizio => crowdfunding.title,
          :emailQuietanza => user_investment_params[:email], # user_investment.user.email,
          :idFiscaleCliente => user_investment_params[:fiscal_code], #"RSSNTN81A05B519S"
          :idServizio => crowdfunding.id,
          :identificativoCredito => credit_id,
          :importoServizio => user_investment_params[:value_investements],
          :infoAggiuntive => ""
      }
    else
      payment_data = {
          :callBackUrlOrganizzazione => Rails.application.config.root_path + payment_outcome_crowdfunding_path(crowdfunding.id),
          :callBackEndpointWsUrlOrganizzazione => Rails.application.config.root_path + Rails.application.config.wsdl_path,
          :causale => Rails.application.config.prefix_causale + causale.split(' ').join('-').first(100).to_s,
          :codiceCategoriaServizio => Setting['crowdfunding.codiceCategoriaServizio', User.pon_id],
          :codiceOrganizzazione => Setting['crowdfunding.codiceOrganizzazione', User.pon_id],
          :denominazioneCliente => user_investment_params[:investor], # user_investment.user.username
          :descrizioneServizio => crowdfunding.title,
          :emailQuietanza => user_investment_params[:email], # user_investment.user.email,
          :idFiscaleCliente => user_investment_params[:fiscal_code], # user_investment.user.cod_fiscale,
          :idServizio => crowdfunding.id,
          :identificativoCredito => credit_id,
          :importoServizio => user_investment_params[:value_investements],
          :infoAggiuntive => ""
      }
    end

    json_payload = {:paymentData => payment_data.to_json,
                    :j_username =>  Rails.application.config.crow_username,
                    :j_password =>  Rails.application.config.crow_passwd}

    begin
      response = RestClient::Request.execute(
          method: :post,
          url: Rails.application.config.mypay_url,
          headers: {
              'Content-Type' => "application/json",
              params: json_payload
          }
      )

      # La response arriva in JSON, la converto in un hash:
      parsed_response = JSON.parse(response)

      # Aggiungo credit_id alla response, ci servirà per salvarlo nel database
      parsed_response["credit_id"] = credit_id

    rescue SocketError => e
      logger.error "----------In Socket errror"
      logger.error e.to_s
      redirect_to :back, :flash => {:alert => t('reportings.index.featured_reportings_error')}
    rescue RestClient::ExceptionWithResponse => e
      logger.error "----------In E errror"
      logger.error e.to_s
      redirect_to :back, :flash => {:alert => t('reportings.index.featured_reportings_error')}
    end

    parsed_response
  end

  def load_data
    @user_investment = UserInvestment.find(params[:id])
    @crowdfunding = Crowdfunding.find_by(id: @user_investment.crowdfunding_id)
  end

  ##
  # Si occupa di caricare nell'oggetto user_investment
  # i dati corretti dal db per i campi pre-compilati,
  # per evitare un uso malizioso della form
  def load_current_data
    if current_user
      if current_user.is_spid?
        {
            # investor: current_user.username,
            email: current_user.email,
            fiscal_code: current_user.cod_fiscale
        }
      elsif current_user.is_social?
        {
            # email: current_user.email
        }
      end
    else
      {}
    end
  end

end
