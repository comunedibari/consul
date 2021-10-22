class DebateNotificationsController < ApplicationController
  load_and_authorize_resource except: [:new]

  def new
    @debate = Debate.find(params[:debate_id])
    @notification = DebateNotification.new(debate_id: @debate.id)
    authorize! :new, @notification
  end

  def create
    @notification = DebateNotification.new(debate_notification_params)
    @debate = Debate.find(debate_notification_params[:debate_id])
    if @notification.save
      @debate.users_to_notify.each do |user|
        Notification.add(user, @notification)
      end
      redirect_to @notification, notice: I18n.t("flash.actions.create.crowdfunding_notification")
    else
      render :new
    end
  end

  def show
    @notification = DebateNotification.find(params[:id])
  end

  private

    def debate_notification_params
      params.require(:debate_notification).permit(:title, :body, :debate_id)
    end

end
