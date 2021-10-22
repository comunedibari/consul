class Admin::Moderation::CrowdfundingsController < Admin::BaseController
  #include FeatureFlags
  include ServiceFlags

  include Gamification
 
  gamification :Crowdfunding

  has_filters %w{without_confirmed_hide all_admin with_confirmed_hide}, only: :index

  service_flag  :crowdfundings

  before_action :load_crowdfunding, only: [:confirm_hide, :restore]

  def index
    @crowdfundings = Crowdfunding.by_user_pon.mod_pending_admin.send(@current_filter).order(hidden_at: :desc).page(params[:page])
  end

  def confirm_hide
    #logger.debug "---------------hide admin"
    @crowdfunding.confirm_hide
    restore_event(@crowdfunding, false)
    redirect_to request.query_parameters.merge(action: :index)
  end

  def restore
    #logger.debug "---------------restore admin"
    @crowdfunding.restore
    @crowdfunding.ignore_flag
    Activity.log(current_user, :restore, @crowdfunding)
    if @crowdfunding.moderation_date
      self.action_user = @crowdfunding.author
      self.action_attribute = "create"
    end
    restore_event(@crowdfunding, true)
    redirect_to request.query_parameters.merge(action: :index)
  end

  private

    #riprstina o nasconde l'evento associato all'oggetto
    def restore_event(resource, flag)
      if resource.event_content
        id = resource.event_content.event_id
        event = Event.with_hidden.where(id: id).first
        event.hidden_at= flag ? nil : Time.current
        event.save
      end
    end

    def load_crowdfunding
      @crowdfunding = Crowdfunding.by_user_pon.find(params[:id])
    end

end
