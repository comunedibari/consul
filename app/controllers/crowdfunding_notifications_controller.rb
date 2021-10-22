class CrowdfundingNotificationsController < ApplicationController
  load_and_authorize_resource except: [:new]

  def new
    @crowdfunding = Crowdfunding.find(params[:crowdfunding_id])
    @notification = CrowdfundingNotification.new(crowdfunding_id: @crowdfunding.id)
    authorize! :new, @notification
  end

  def create
    @notification = CrowdfundingNotification.new(crowdfunding_notification_params)
    @crowdfunding = Crowdfunding.find(crowdfunding_notification_params[:crowdfunding_id])
    if @notification.save
      @crowdfunding.users_to_notify.each do |user|
        Notification.add(user, @notification)
      end
      redirect_to @notification, notice: I18n.t("flash.actions.create.crowdfunding_notification")
    else
      render :new
    end
  end

  def show
    @notification = CrowdfundingNotification.find(params[:id])
  end

  private

    def crowdfunding_notification_params
      params.require(:crowdfunding_notification).permit(:title, :body, :crowdfunding_id)
    end

end
