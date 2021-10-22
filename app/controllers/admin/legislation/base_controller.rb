class Admin::Legislation::BaseController < Admin::BaseController
  before_action :load_process
  include FeatureFlags

  #feature_flag :legislation
  
  helper_method :namespace

  def set_in_moderation
    if current_user.administrator? || current_user.moderator?
      @process.moderation_entity = 1 
    else
      @process.moderation_entity = 2
    end  
    @process.save
  end

  private

    def verify_administrator
    end  

    def namespace
      "admin"
    end

    def load_process
      @process = ::Legislation::Process.unscoped.find(params[:process_id])
    end

end
