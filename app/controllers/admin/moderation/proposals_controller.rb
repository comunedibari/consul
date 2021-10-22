class Admin::Moderation::ProposalsController < Admin::BaseController
  #include FeatureFlags
  include ServiceFlags
  include Gamification

 
  gamification :Proposal

  has_filters %w{without_confirmed_hide all_admin with_confirmed_hide}, only: :index

  #feature_flag :proposals
  service_flag  :proposals

  before_action :load_proposal, only: [:confirm_hide, :restore]

  def index
    @proposals = Proposal.by_user_pon.mod_pending_admin.send(@current_filter).order(hidden_at: :desc).page(params[:page])
  end

  def confirm_hide
    @proposal.confirm_hide
    redirect_to request.query_parameters.merge(action: :index)
  end 

  def restore
    @proposal.restore
    @proposal.ignore_flag
    Activity.log(current_user, :restore, @proposal)
    if @proposal.moderation_date
      self.action_user = @proposal.author
      self.action_attribute = "create"
    end
    redirect_to request.query_parameters.merge(action: :index)
  end



  private

    def load_proposal
      @proposal = Proposal.by_user_pon.find(params[:id])
    end

end
