class Admin::Moderation::EventsController < Admin::BaseController
  #include FeatureFlags
  include ServiceFlags

  has_filters %w{without_confirmed_hide all_admin with_confirmed_hide}, only: :index

  service_flag  :events

  before_action :load_event, only: [:confirm_hide, :restore]

  def index
    @events = Event.by_user_pon.mod_pending_admin.send(@current_filter).order(hidden_at: :desc).page(params[:page])
  end

  def confirm_hide
    @event.confirm_hide
    redirect_to request.query_parameters.merge(action: :index)
  end

  def restore
    @event.restore
    @event.ignore_flag
    Activity.log(current_user, :restore, @event)
    redirect_to request.query_parameters.merge(action: :index)
  end

  private

    def load_event
      @event = Event.by_user_pon.find(params[:id])
    end

end
