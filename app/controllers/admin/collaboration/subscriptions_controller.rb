class Admin::Collaboration::SubscriptionsController < Admin::Collaboration::BaseController

  load_and_authorize_resource :collaboration_subscription, class: "Collaboration::Subscription"
  before_action :load_data, only: [:new]





  def new
      @subscription = Collaboration::Subscription.new()
  end

  def create
      #@subscription = Collaboration::Subscription.find(params[:id])
      @subscription = Collaboration::Subscription.new(collaboration_subscription_params)
      if @subscription.save
        
        redirect_to @subscription, notice: I18n.t("flash.actions.create.proposal_notification")
      else
        render :new
      end
  end
  

  def load_data
      @collaboration_agreement = Collaboration::Agreement.find(params[:collaboration_agreement])
  end



  def agreement_type
      [2]
  end

  private
      def collaboration_subscription_params
          params.require(:collaboration_subscription).permit(:title, :collaboration_agreement_id)
      end
end
