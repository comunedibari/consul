#moderazione su reporting

class Admin::Moderation::ReportingsController < Admin::BaseController
  #include FeatureFlags
  include ServiceFlags

  has_filters %w{without_confirmed_hide all_admin with_confirmed_hide}, only: :index

  service_flag  :reportings

  before_action :load_reporting, only: [:confirm_hide, :restore]

  def index
    @reportings = Reporting.by_user_pon.mod_pending_admin.send(@current_filter).order(hidden_at: :desc)
                         .page(params[:page])
  end

  def confirm_hide
    @reporting.confirm_hide
    redirect_to request.query_parameters.merge(action: :index)
  end

  def restore
    @reporting.restore
    @reporting.ignore_flag
    Activity.log(current_user, :restore, @reporting)
    redirect_to request.query_parameters.merge(action: :index)
  end

  private

    def load_reporting
      @reporting = Reporting.by_user_pon.with_hidden.find(params[:id])
    end

end
