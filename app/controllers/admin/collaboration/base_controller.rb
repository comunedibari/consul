class Admin::Collaboration::BaseController < Admin::BaseController
  before_action :load_agreement
  include FeatureFlags

  #feature_flag :legislation
  
  helper_method :namespace

  def set_in_moderation
    if current_user.administrator? || current_user.moderator?
      @agreement.moderation_entity = 1 
    else
      @agreement.moderation_entity = 2
    end  
    @agreement.save
  end

  private

    def verify_administrator
    end  

    def namespace
      "admin"
    end

    def load_agreement
      @agreement = ::Collaboration::Agreement.unscoped.find(params[:agreement_id])
    end

end
