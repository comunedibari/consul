class ReportingNotificationsController < ApplicationController
    load_and_authorize_resource except: [:new]
  
    def new
      @reporting = Reporting.find(params[:reporting_id])
      @notification = ReportingNotification.new(reporting_id: @reporting.id)
      authorize! :new, @notification
    end
  
    def create
      @notification = ReportingNotification.new(reporting_notification_params)
      @reporting = Reporting.find(reporting_notification_params[:reporting_id])
      if @notification.save
        @reporting.users_to_notify.each do |user|
          Notification.add(user, @notification)
        end
        redirect_to @notification, notice: I18n.t("flash.actions.create.proposal_notification")
      else
        render :new
      end
    end
  
    def show
      @notification = ReportingNotification.find(params[:id])
    end
  
    private
  
      def reporting_notification_params
        params.require(:reporting_notification).permit(:title, :body, :reporting_id)
      end
  
  end
  