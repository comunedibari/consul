class Collaboration::AgreementNotificationsController < ApplicationController
  load_and_authorize_resource class: "Collaboration::AgreementNotification",  except: [:new]

  def new
    @collaboration_agreement = Collaboration::Agreement.find(params[:collaboration_agreement_id])
    @notification = Collaboration::AgreementNotification.new(collaboration_agreement_id: @collaboration_agreement.id)
    authorize! :new, @notification
  end

  def create
    @notification = Collaboration::AgreementNotification.new(agreement_notification_params)
    @collaboration_agreement = Collaboration::Agreement.find(agreement_notification_params[:collaboration_agreement_id])
    if @notification.save
      @collaboration_agreement.users_to_notify.each do |user|
        Notification.add(user, @notification)
      end
      redirect_to @notification, notice: I18n.t("flash.actions.create.proposal_notification")
    else
      render :new
    end
  end

  def show
    @notification = Collaboration::AgreementNotification.find(params[:id])
  end

  private

    def agreement_notification_params
      params.require(:collaboration_agreement_notification).permit(:title, :body, :collaboration_agreement_id)
    end

end
