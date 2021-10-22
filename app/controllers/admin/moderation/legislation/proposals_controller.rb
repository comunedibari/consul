class Admin::Moderation::Legislation::ProposalsController < Admin::BaseController
  #include FeatureFlags
  include ServiceFlags

  service_flag  :processes 

  has_filters %w{without_confirmed_hide all_admin with_confirmed_hide}, only: :index

  before_action :load_process, only: [:confirm_hide, :restore]

  load_resource :process, class: 'Legislation::Proposal'

  def index
    @proposals = ::Legislation::Proposal.mod_pending_admin.send(@current_filter).order(hidden_at: :desc).page(params[:page])
  end

  def confirm_hide
    @proposal.confirm_hide
    redirect_to request.query_parameters.merge(action: :index)
  end

  def restore
    @proposal.moderation_entity = 1
    @proposal.save
    @proposal.after_restore
    Activity.log(current_user, :restore, @process)
    redirect_to request.query_parameters.merge(action: :index)
  end



  private

    def load_process
      @proposal = ::Legislation::Proposal.find(params[:id])
    end

end