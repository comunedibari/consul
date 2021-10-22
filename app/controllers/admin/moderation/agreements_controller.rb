class Admin::Moderation::AgreementsController < Admin::BaseController
  #include FeatureFlags
  include ServiceFlags



  include Gamification
 
  gamification "Collaboration::Agreement"


  


  service_flag  :collaboration 

  has_filters %w{without_confirmed_hide all_admin with_confirmed_hide}, only: :index

  before_action :load_agreement, only: [:confirm_hide, :restore]

  load_resource :agreement, class: '::Collaboration::Agreement'

  def index
    @agreements = ::Collaboration::Agreement.by_user_pon.mod_pending_admin.send(@current_filter).order(hidden_at: :desc).page(params[:page])
  end

  def confirm_hide
    @agreement.confirm_hide
    redirect_to request.query_parameters.merge(action: :index)
  end

  def restore
    @agreement.moderation_entity = 1
    @agreement.save
    @agreement.after_restore
    Activity.log(current_user, :restore, @agreement)
    if !@agreement.moderation_date
      self.action_user = @agreement.author
      self.action_attribute = "create"
    end
    redirect_to request.query_parameters.merge(action: :index)
  end



  private

    def load_agreement
      @agreement = ::Collaboration::Agreement.by_user_pon.find(params[:id])
    end

end