class Admin::Moderation::DebatesController < Admin::BaseController
  #include FeatureFlags
  include ServiceFlags
  include Gamification


 
  gamification :Debate

  #feature_flag :debates
  service_flag  :debates

  has_filters %w{without_confirmed_hide all_admin with_confirmed_hide}, only: :index

  before_action :load_debate, only: [:confirm_hide, :restore]

  def index
    @debates = Debate.by_user_pon.mod_pending_admin.send(@current_filter).order(hidden_at: :desc).page(params[:page])
  end

  def confirm_hide
    @debate.confirm_hide
    redirect_to request.query_parameters.merge(action: :index)
  end

  def restore    
    @debate.restore
    #@debate.moderation_entity = 1
    @debate.ignore_flag
    @debate.save
    Activity.log(current_user, :restore, @debate)
    if @debate.moderation_date
      self.action_user = @debate.author
      self.action_attribute = "create"
    end
    redirect_to request.query_parameters.merge(action: :index)
  end

  private

    def load_debate
      @debate = Debate.by_user_pon.find(params[:id])
    end

end
