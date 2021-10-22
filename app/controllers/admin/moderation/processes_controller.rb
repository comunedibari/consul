class Admin::Moderation::ProcessesController < Admin::BaseController
  #include FeatureFlags
  include ServiceFlags

  include Gamification
  
  gamification "Legislation::Proposal"
  service_flag  :processes 

  has_filters %w{without_confirmed_hide all_admin with_confirmed_hide}, only: :index

  before_action :load_process, only: [:confirm_hide, :restore]

  load_resource :process, class: '::Legislation::Process'

  def index
    @processes = ::Legislation::Process.by_user_pon.mod_pending_admin.send(@current_filter).order(hidden_at: :desc).page(params[:page])
  end

  def confirm_hide
    @process.confirm_hide
    redirect_to request.query_parameters.merge(action: :index)
  end

  def restore
    @process.moderation_entity = 1
    @process.save
    @process.after_restore
    Activity.log(current_user, :restore, @process)
    if @process.moderation_date
      self.action_user = @process.author
      self.action_attribute = "create"
    end
    redirect_to request.query_parameters.merge(action: :index)
  end



  private

    def load_process
      @process = ::Legislation::Process.by_user_pon.find(params[:id])
    end

end
