class Admin::SettingsController < Admin::BaseController

  def index
    all_settings = Setting.all.pon(current_user.pon_id).enabled.group_by { |s| s.type }
    @settings = all_settings['common']
    @feature_flags = all_settings['feature']
    @service_flags = all_settings['service']
    @description = all_settings['service_description']

    @social = all_settings['service_social']

    @moderation_flags = all_settings['moderation']
    @banner_styles = all_settings['banner-style']
    @banner_imgs = all_settings['banner-img']

    @ente_images = all_settings['ente_logo']
    @subheader_images = all_settings['sub_header']

    @crowdfundings = all_settings['crowdfunding']

    @user = current_user
    #@jobs = [ "GamificationHourlyJob", "GamificationMonthlyJob", "SgapDownloadDataJob", "BisDownloadDataJob", "RecoverTagNotificationsJob", "SendEmailModerableBookingsJob"]
    @jobs = all_settings['job']
  end

  def update
    @setting = Setting.find(params[:id])
    @setting.update(settings_params)
    tab_setting = @setting.key.start_with?("service") ? "service" : "global"
    tab_setting = @setting.key.end_with?(".image") ? "global" : tab_setting
    tab_setting = @setting.key.start_with?("feature") ? "feature" : tab_setting
    redirect_to admin_settings_path(tab_setting: tab_setting), notice: t("admin.settings.flash.updated")
  end

  def update_map
    Setting["map_latitude",current_user.pon_id] = params[:latitude].to_f
    Setting["map_longitude",current_user.pon_id] = params[:longitude].to_f
    Setting["map_zoom",current_user.pon_id] = params[:zoom].to_i
    redirect_to admin_settings_path(tab_setting: "map"), notice: t("admin.settings.index.map.flash.update")
  end

  def exec_job
    #@job = Setting.find(key: params[:key])
    #@job = Setting.where("id=?", params[:format]).first
    job = params[:key]
    case job.to_s
    when "job.recover_tag_notifications_job"
      RecoverTagNotificationsJob.perform_later
      flash[:notice] = t("admin.settings.index.job.notice.recover_tag_notifications_job")
    when "job.sgap_download_data_job"
      SgapDownloadDataJob.perform_later
      flash[:notice] = t("admin.settings.index.job.notice.sgap_download_data_job")
    when "job.bis_download_data_job"
      BisDownloadDataJob.perform_later 
      flash[:notice] = t("admin.settings.index.job.notice.bis_download_data_job")
    when "job.gamification_monthly_job"
      GamificationMonthlyJob.perform_later
      flash[:notice] = t("admin.settings.index.job.notice.gamification_monthly_job")
    when "job.gamification_hourly_job"
      GamificationHourlyJob.perform_later
      flash[:notice] = t("admin.settings.index.job.notice.gamification_hourly_job")
    when "job.reportings_download_data_job"
      ReportingsDataJob.perform_later
      flash[:notice] = t("admin.settings.index.job.notice.reportings_download_data_job")  
    when "job.all_reportings_download_data_job"
      AllReportingsDataJob.perform_later
      flash[:notice] = t("admin.settings.index.job.notice.all_reportings_download_data_job") 
    when "job.bis_process_download_data_job"
      BisProcessDownloadDataJob.perform_later
      flash[:notice] = t("admin.settings.index.job.notice.bis_process_download_data_job")  
    else
      flash[:error] = t("admin.settings.index.job.error")
    end
    redirect_to admin_settings_path(tab_setting: "job")
  end


  private

    def settings_params
      params.require(:setting).permit(:value,
        images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy])
    end

end
