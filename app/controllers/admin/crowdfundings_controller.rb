class Admin::CrowdfundingsController < Admin::BaseController
  include ServiceFlags
  include CommentableActions
  include FlagActions
  include NotificationsHelper
  include Eventify

  include Gamification

  gamification :Crowdfunding


  service_flag :crowdfundings
  has_filters %w{opens next past}, only: [:index]

  before_action :load_data, only: [:edit, :update, :show, :debate, :proposal, :result_publication, :allegations, :draft_publication, :sgap, :rewards, :investments, :approve_investment, :delete_investment]
  before_action :load_categories, only: [:index, :new, :create, :edit, :toedit, :summary]
  before_action :parse_tag_filter, only: [:index]
  before_action :load_tag_cloud

  load_and_authorize_resource :crowdfunding, class: "::Crowdfunding"

  respond_to :html, :js

  has_orders ->(c) { Crowdfunding.crowdfundings_orders(c.current_user) }, only: :index

  skip_authorization_check only: [:json_data]


  def create
    #@crowdfunding = Crowdfunding.new(crowdfunding_params.merge(author: current_user,pon_id: current_user.pon_id))
    @crowdfunding = Crowdfunding.new(crowdfunding_params.merge(author: current_user, pon_id: session[:pon_id]))
    @crowdfunding.total_investiment = 0
    @crowdfunding.count_investors = 0

    if @crowdfunding.save
      if crowdfunding_params[:sector_id].present? and crowdfunding_params[:sector_id].to_i > 0
        sector = Sector.find(crowdfunding_params[:sector_id].to_i)
        SectorContent.create(sectorable: @crowdfunding, sector: sector)
      end

      if current_user.administrator?
        if params[:crowdfunding][:social_content][:social_access].to_i > 0
          SocialContent.create(sociable: @crowdfunding, social_access: true)
        else
          SocialContent.create(sociable: @crowdfunding, social_access: false)
        end
      else
        social_service = Setting.find_by(key: 'service_social.crowdfundings', pon_id: User.pon_id).value
        SocialContent.create(sociable: @crowdfunding, social_access: social_service)
      end
      # #creazione dell'evento associato
      event = create_as_event(@crowdfunding)
      #add geolocation to crowdfunding if exists user coords
      event.update_attribute(:hidden_at, nil)
      redirect_to share_crowdfunding_path(@crowdfunding), notice: I18n.t('flash.actions.create.crowdfunding')
      send_notification_tags(@crowdfunding)
    else
      render :new
    end
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
  end

  def edit
    super
    @crowdfunding.sector_id = @crowdfunding.sector_content.present? ? @crowdfunding.sector_content.sector.id : nil
  end

  def update
    super
    if @crowdfunding.sector_content.present?
      @crowdfunding.sector_content.destroy
    end

    if crowdfunding_params[:sector_id].present? and crowdfunding_params[:sector_id].to_i > 0
      sector = Sector.find(crowdfunding_params[:sector_id].to_i)
      SectorContent.create(sectorable: @crowdfunding, sector: sector)
    end
    #--------------------------------------
    if current_user.provider == "openam" && current_user.administrator?
      if params[:crowdfunding][:social_content][:social_access].present?
        if params[:crowdfunding][:social_content][:social_access].to_i > 0
          @social_content.update_attribute(:social_access, true)
        else
          @social_content.update_attribute(:social_access, false)
        end
      end
    end

    if @crowdfunding.event_content
      event = update_event(@crowdfunding)
      if current_user.administrator? || current_user.moderator?
        event.update_attribute(:hidden_at, nil)
      end
    end
  end

  def verify_administrator
    raise CanCan::AccessDenied unless current_user.present?
  end

  def destroy
    event = @crowdfunding.event_content.event
    event.destroy
    @crowdfunding.destroy
    redirect_to admin_crowdfundings_path, notice: t('flash.actions.destroy.budget_investment')
  end

  def investments
    @user_investments = @crowdfunding.user_investments.order(created_at: :desc).page(params[:page]).per(10)

  end

  def rewards
    @crowdfunding_reward = CrowdfundingReward.new
    @crowdfunding_reward.min_investment = @crowdfunding.min_price
    @rewards = @crowdfunding.crowdfunding_rewards.order(min_investment: :asc).page(params[:page]).per(5)
  end

  def approve_investment
    i_id = params[:user_investment_id]
    @user_investment = UserInvestment.where(id: i_id).first
    #aggiorna i dati
    accepted_status
    number_investors = UserInvestment.select(:user_id).where(crowdfunding_id: @crowdfunding.id).where(status: "accepted").uniq.count
    total_investment = UserInvestment.where(crowdfunding_id: @crowdfunding.id).where(status: "accepted").sum(:value_investements)
    #total_investment = @crowdfunding.total_investiment.to_i + @user_investment.value_investements.to_f
    @crowdfunding.update_attribute(:count_investors, number_investors)
    @crowdfunding.update_attribute(:total_investiment, total_investment)

    if @crowdfunding.financed?
      insert_user_action(self.action_service, @crowdfunding.author, "financed")
    end

    redirect_to investments_admin_crowdfunding_path(@crowdfunding), notice: t("user_investments.form.confirmed_investment")
  end

  def delete_investment
    i_id = params[:user_investment_id]
    @user_investment = UserInvestment.where(id: i_id).first
    @user_investment.destroy
    redirect_to investments_admin_crowdfunding_path(@crowdfunding), notice: t("user_investments.form.delete_ivestment")
  end

  def load_tag_cloud
    @tag_cloud = tag_cloud
  end

  def resource_model
    Crowdfunding
  end

  def resource_name
    'crowdfunding'
  end

  def set_legislation_crowdfunding_votes(crowdfundings) end

  def index
    @crowdfundings = Crowdfunding.send(@current_filter).by_user_pon.order('id DESC')

    unless can? :update, Crowdfunding
      @crowdfundings = @crowdfundings.by_user(current_user)
    end

    @crowdfundings = @crowdfundings.page(params[:page])
  end

  def large_map
    @crowdfundings = resource_model.all.by_user_pon
  end

  def show
    load_data
  end

  def json_data
    crowdfunding = Crowdfunding.find(params[:id])
    data = {
        crowdfunding_id: crowdfunding.id,
        title: crowdfunding.title,
        url: crowdfundings_path(crowdfunding)
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end

  private

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
                                         :responsible_name, :tag_list, :geozone_id, :skip_map,
                                         :as_rappr_legale, :sector_id, :price_goal, :min_price,
                                         :start_date, :end_date, :contacts_info, :social_access,
                                         :flag_rewards, :flag_refund, :flag_investments, :terms_of_service,
                                         images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                         documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                         map_location_attributes: [:latitude, :longitude, :zoom],
                                         social_content_attributes: [:social_access],
                                         sector_content_attributes: [:sector_id]
    ) #.merge(pon_id: User.pon_id)
        .merge(moderation_entity: moderation_entity_v)
  end

  def accepted_status
    status = "accepted"
    @user_investment.update_attribute(:status, status)
    #@crowdfunding.update_attribute(:total_investiment, @crowdfunding.total_investiment + @user_investment.value_investements)
    #number_investors = UserInvestment.select(:user_id).where(crowdfunding_id: @crowdfunding.id).uniq.count
    #@crowdfunding.update_attribute(:count_investors, number_investors)

  end

  def member_method?
    params[:id].present?
  end

  def load_data
    p_id = params[:id]
    #@author = author_of(p_id)


    if params[:crowdfunding_id].present?
      if params[:crowdfunding_id] != nil
        id = params[:crowdfunding_id]
      end
    end
    @crowdfunding = Crowdfunding.find(p_id)
    if !@crowdfunding.load_entity?(current_user)
      raise CanCan::AccessDenied
    end
  end

end
