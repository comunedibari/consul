class CrowdfundingsController < ApplicationController
  include ServiceFlags
  include CommentableActions
  include FlagActions
  include NotificationsHelper
  include Eventify

  before_action :parse_tag_filter, only: :index
  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary]
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :authenticate_user!, except: [:index, :show, :map, :summary, :json_data, :large_map, :payment_outcome]
  before_action :destroy_map_location_association, only: :update
  before_action :set_view, only: :index
  before_action :load_data, only: [:edit, :update, :show]

  skip_authorization_check only: :json_data

  service_flag :crowdfundings

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders ->(c) { Crowdfunding.crowdfundings_orders(c.current_user) }, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  load_and_authorize_resource
  helper_method :resource_model, :resource_name
  respond_to :html, :js

  # add crowdfunings breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.crowdfundings"), :crowdfundings_path

  def load_data
    @crowdfunding = Crowdfunding.find(params[:id])
    if !@crowdfunding.load_entity?(current_user)
      raise CanCan::AccessDenied
    end
  end

  def large_map
    @crowdfundings = @crowdfundings.by_user_pon
  end

  def show
    super
    load_data
    @notifications = @crowdfunding.notifications
    @related_contents = Kaminari.paginate_array(@crowdfunding.relationed_contents).page(params[:page]).per(5)

    #aggiungo le ricompense
    @crowdfunding_rewards = CrowdfundingReward.all.where(crowdfunding_id: @crowdfunding.id).limit(5)

    #calcolo la percentuale di fondi raccolti
    @investments_percentage = @crowdfunding.total_investiment.to_f / @crowdfunding.price_goal.to_f * 100

    #recupero lista investimenti
    if @crowdfunding.flag_investments
      @investments = Kaminari.paginate_array(load_successful_user_investments).page(params[:inv_list_page]).per(5)
    end

    #recupero lista  "i miei investimenti"
    if current_user
      @current_user_investments = Kaminari.paginate_array(load_current_user_investments).page(params[:my_inv_list_page]).per(5)
    end
  end

  def create
    #@crowdfunding = Crowdfunding.new(crowdfunding_params.merge(author: current_user,pon_id: current_user.pon_id))
    @crowdfunding = Crowdfunding.new(crowdfunding_params.merge(author: current_user, pon_id: session[:pon_id]))
    @crowdfunding.total_investiment = 0
    @crowdfunding.count_investors = 0
    if @crowdfunding.save

      #if crowdfunding_params[:sector_id].present? and crowdfunding_params[:sector_id].to_i > 0
      #  sector = Sector.find(crowdfunding_params[:sector_id].to_i)
      #  SectorContent.create(sectorable: @crowdfunding, sector: sector)
      #end


      if current_user.administrator? or current_user.moderator?
        if params[:crowdfunding][:social_content][:social_access].to_i > 0
          SocialContent.create(sociable: @crowdfunding, social_access: true)
        else
          SocialContent.create(sociable: @crowdfunding, social_access: false)
        end
      #else
      #  social_service = Setting.find_by(key: 'service_social.crowdfundings', pon_id: User.pon_id).value
      #  SocialContent.create(sociable: @crowdfunding, social_access: social_service)
      end


      #creazione dell'evento associato
      event = create_as_event(@crowdfunding)

      #add geolocation to crowdfunding if exists user coords
      if current_user.administrator? || current_user.moderator?
        event.update_attribute(:hidden_at, nil)
        redirect_to share_crowdfunding_path(@crowdfunding), notice: I18n.t('flash.actions.create.crowdfunding')
        send_notification_tags(@crowdfunding)
      else
        redirect_to user_path(current_user), notice: I18n.t('flash.actions.create.crowdfunding_in_approval')
      end


    else
      render :new
    end
  end

  def edit
    super
    #@crowdfunding.sector_id = @crowdfunding.sector_content.present? ? @crowdfunding.sector_content.sector.id : nil
  end

  def update
    super
    #gestione terzo settore disattivata
    #if @crowdfunding.sector_content.present?
    #  @crowdfunding.sector_content.destroy
    #end
    #if crowdfunding_params[:sector_id].present? and crowdfunding_params[:sector_id].to_i > 0
    #  sector = Sector.find(crowdfunding_params[:sector_id].to_i)
    #  SectorContent.create(sectorable: @crowdfunding, sector: sector)
    #end
    #--------------------------------------
    #if current_user.provider == "openam" && current_user.administrator?
      if params[:crowdfunding][:social_content][:social_access].present?
        @social_content = SocialContent.where(sociable_type: 'Crowdfunding').where(sociable_id: @crowdfunding.id).first
        if params[:crowdfunding][:social_content][:social_access].to_i > 0
          @social_content.update_attribute(:social_access, true)
        else
          @social_content.update_attribute(:social_access, false)
        end
      end
    #end

    if @crowdfunding.event_content
      event = update_event(@crowdfunding)
      if current_user.administrator? || current_user.moderator?
        event.update_attribute(:hidden_at, nil)
      end
    end
  end

  def moderation_flag
    crowdfunding = Crowdfunding.find_by(id: params[:id])
    crowdfunding.moderation_flag = !crowdfunding.moderation_flag
    crowdfunding.save
    redirect_to :back, notice: t('notice.operaction_successfull')
  end

  def social_flag
    @crowdfunding = Crowdfunding.find_by(id: params[:id])

    @crowdfunding.social_content.social_access = !@crowdfunding.social_content.social_access
    @crowdfunding.social_content.save
    @crowdfunding.touch
    redirect_to :back, notice: t('notice.operaction_successfull')
  end

  def index_customization
    discard_archived
    load_retired
    load_successful_crowdfundings
    #commento per disabilitare il pannello in evidenzia
    #load_featured unless @crowdfunding_successful_exists
  end

  def vote
    @crowdfunding.register_vote(current_user, 'yes')
    set_crowdfunding_votes(@crowdfunding)
  end

  def retire
    if valid_retired_params? && @crowdfunding.update(retired_params.merge(retired_at: Time.current))
      redirect_to crowdfunding_path(@crowdfunding), notice: t('crowdfundings.notice.retired')
    else
      render action: :retire_form
    end
  end

  def retire_form
  end

  def share
    if Setting['crowdfunding_improvement_path', User.pon_id].present?
      @crowdfunding_improvement_path = Setting['crowdfunding_improvement_path', User.pon_id]
    end
  end

  def vote_featured
    @crowdfunding.register_vote(current_user, 'yes')
    set_featured_crowdfunding_votes(@crowdfunding)
  end

  def summary
    @crowdfundings = Crowdfunding.by_user_pon.for_summary
    @tag_cloud = tag_cloud
  end

  def json_data
    crowdfunding = Crowdfunding.find(params[:id])
    data = {
        crowdfunding_id: crowdfunding.id,
        title: crowdfunding.title,
        author_id: crowdfunding.author_id,
        url: crowdfunding_path(crowdfunding)
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end

  def destroy
    destroy_event(@crowdfunding)
    @crowdfunding.destroy
    redirect_to user_path(current_user, filter: 'crowdfundings'), notice: t('flash.actions.destroy.budget_investment')
  end


  ##
  # Gestisce il valore di ritorno dal portale pagamenti esterno
  #
  # I parametri nella GET in arrivo sono
  # id_p => identificativo pagamento, che corrisponderà con l'identificativoPagamento dello user_investment
  # idSession => ID sessione, non utilizzato al momento
  # esito => Può essere "ERROR" in caso di fallimento oppure "OK" in caso di successo
  def payment_outcome
    if request.query_parameters[:id_p].present? and request.query_parameters[:esito].present?
      identificativo_pagamento = request.query_parameters[:id_p]
      esito_pagamento = request.query_parameters[:esito]
    else
      flash[:alert] = t('crowdfundings.user_investments.errors.canceled_payment')
      redirect_to crowdfundings_path
      return
    end

    # Ricavo lo user investment dall'identificativo pagamento e procedo con la logica
    begin
      user_investment = UserInvestment.find_by! payment_id: identificativo_pagamento

      if esito_pagamento == 'OK'
        flash[:notice] = t('crowdfundings.user_investments.share.created')
        redirect_to share_crowdfunding_user_investment_path(user_investment.crowdfunding_id, user_investment)
      else
        flash[:alert] = t('crowdfundings.user_investments.errors.canceled_payment')
        redirect_to crowdfunding_path(user_investment.crowdfunding_id)
        user_investment.destroy
      end

    rescue ActiveRecord::RecordNotFound
      flash[:alert] = t('crowdfundings.user_investments.errors.payment_id_not_found')
      redirect_to crowdfundings_path
    end

  end

  private

  def load_successful_user_investments
    UserInvestment.all.where(crowdfunding_id: @crowdfunding.id).where(status: UserInvestment.statuses[:accepted]).order(created_at: :desc)
  end

  def load_current_user_investments
    UserInvestment.all.where(crowdfunding_id: @crowdfunding.id).where(user_id: current_user.id).order(created_at: :desc)
  end

  def send_notification_tags(resource)
    send_notification_for_tags(resource)
  end

  def crowdfunding_params
    if current_user.administrator? || current_user.moderator?
      moderation_entity_v = 1
    else
      moderation_entity_v = 2
    end
    params.require(:crowdfunding).permit(:title, :question, :summary, :description, :external_url, :video_url,
                                         :responsible_name, :tag_list, :terms_of_service, :geozone_id, :skip_map,
                                         :as_rappr_legale, :sector_id, :price_goal, :min_price,
                                         :start_date, :end_date, :contacts_info, :social_access, :flag_rewards, :flag_refund, :flag_investments,
                                         images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                         documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                         map_location_attributes: [:latitude, :longitude, :zoom],
                                         social_content_attributes: [:social_access],
                                         sector_content_attributes: [:sector_id]
    ) #.merge(pon_id: User.pon_id)
        .merge(moderation_entity: moderation_entity_v)
  end

  def retired_params
    params.require(:crowdfunding).permit(:retired_reason, :retired_explanation)
  end

  def valid_retired_params?
    @crowdfunding.errors.add(:retired_reason, I18n.t('errors.messages.blank')) if params[:crowdfunding][:retired_reason].blank?
    @crowdfunding.errors.add(:retired_explanation, I18n.t('errors.messages.blank')) if params[:crowdfunding][:retired_explanation].blank?
    @crowdfunding.errors.empty?
  end

  def resource_model
    Crowdfunding
  end

  def set_featured_crowdfunding_votes(crowdfundings)
    @featured_crowdfundings_votes = current_user ? current_user.crowdfunding_votes(crowdfundings) : {}
  end

  def discard_archived
    @resources = @resources.not_archived unless @current_order == "archival_date"
  end

  def load_retired
    if params[:retired].present?
      @resources = @resources.retired
      @resources = @resources.where(retired_reason: params[:retired]) if Crowdfunding::RETIRE_OPTIONS.include?(params[:retired])
    else
      @resources = @resources.not_retired
    end
  end

  def load_featured
    return unless !@advanced_search_terms && @search_terms.blank? && @tag_filter.blank? && params[:retired].blank? && @current_order != "recommendations"
    @featured_crowdfundings = Crowdfunding.where(moderation_entity: 1).by_user_pon.not_archived.sort_by_confidence_score.limit(3)
    if @featured_crowdfundings.present?
      set_featured_crowdfunding_votes(@featured_crowdfundings)
      @resources = @resources.where('crowdfundings.id NOT IN (?)', @featured_crowdfundings.map(&:id))
    end
  end

  def set_view
    @view = (params[:view] == "minimal") ? "minimal" : "default"
  end

  def load_successful_crowdfundings
    @crowdfunding_successful_exists = Crowdfunding.by_user_pon.successful.exists?
  end

  def destroy_map_location_association
    map_location = params[:crowdfunding][:map_location_attributes]
    skip_map = params[:crowdfunding][:skip_map]
    if skip_map == "1" || (map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?)
      MapLocation.destroy(map_location[:id])
    end
  end

end
