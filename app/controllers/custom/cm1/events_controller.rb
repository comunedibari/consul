class EventsController < ApplicationController

  include FlagActions
  include CommentableActions
  include NotificationsHelper
  include ServiceFlags
  include Gamification

  gamification :Event

  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :parse_tag_filter, only: :index
  before_action :set_view, only: :index
  before_action :authenticate_user!, except: [:index, :show, :map, :summary, :json_data, :large_map]
  before_action :destroy_map_location_association, only: :update
  before_action :load_data, only: [:edit, :update, :show] #moderazione su event
  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary] #miaaa


  service_flag :events
  skip_authorization_check only: :json_data
  load_and_authorize_resource
  respond_to :html, :js

  has_orders ->(c) {Event.events_orders(c.current_user)}, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  #add eventi breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.events"), :events_path

  def load_data_extended
    id_events = Array.new
    @events.each do |single|
      id_events.push(single.id)
    end
    @event_slots = EventSlot.where(event_id: id_events).joins(:event).all
  end

  def index_customization
    @featured_events = @events.featured
  end


  def events_list

    json.array!(@events) do |event|
      json.extract! event, :id, :title, :description
      json.start event.start_event
      json.end event.end_event
    end
    json
  end

  def new
    @event = Event.new
  end

  def edit
  end

  def resource_model
    Event
  end

  def create
    #@event = Event.new(event_params.merge(author: current_user, pon_id: current_user.pon_id))
    @event = Event.new(event_params.merge(author: current_user, pon_id: session[:pon_id]))
    if @event.save

      if current_user.administrator? || current_user.moderator?
        redirect_to share_event_path(@event), notice: I18n.t('flash.actions.create.event')
        send_notification_tags(@event)
      else
        redirect_to user_path(current_user), notice: I18n.t('flash.actions.create.event_in_approval') #moderazione su event
      end




      if current_user.administrator?
        if params[:event][:social_content][:social_access].to_i > 0
          SocialContent.create(sociable: @event, social_access: true)
        else
          SocialContent.create(sociable: @event, social_access: false)
        end
      else
        social_service = Setting.find_by(key: 'service_social.events',pon_id: User.pon_id).value
        SocialContent.create(sociable: @event, social_access: social_service)
      end


    else
      render :new
    end
  end

  def social_flag
    @event = Event.find_by(id: params[:id])

    #@social_content = SocialContent.where(sociable_type: 'Event').where(sociable_id: @event.id).first
    #@social_content.update_attribute(:social_access, !@social_content.social_access)
    #@event.social_content.social_access = @social_content.social_access
    @event.social_content.social_access = !@event.social_content.social_access
    @event.social_content.save
    @event.touch

    redirect_to :back, notice: t('notice.operaction_successfull')
  end

  def update

    super
    @social_content = SocialContent.where(sociable_type: 'Event').where(sociable_id: @event.id).first
      if current_user.provider == "openam" || current_user.administrator?
        if params[:event][:social_content][:social_access].present?
          if params[:event][:social_content][:social_access].to_i > 0
            @social_content.update_attribute(:social_access, true)
          else
            @social_content.update_attribute(:social_access, false)
          end
        end
      end
    # if @event.update(event_params)
    #   #modifiche mappa
    #   if params[:event][:skip_map].to_i == 1 && @event.map_location
    #     MapLocation.destroy(@event.map_location.id)
    #   end
    #   #fine

    #   redirect_to event_path, notice: t("flash.actions.save_changes.notice")
    # else
    #   @event.errors.messages.delete(:organization)
    #   render :update
    # end

  end

  def show
    super
    load_data
  end

  def retire_form
  end

  def destroy
    @event.destroy
  end

  def load_data
    @event = Event.find(params[:id])
    @event_slots = EventSlot.where(event_id: @event.id)

    if !@event.load_entity?(current_user)
      raise CanCan::AccessDenied
    end
  end


  def json_data
    event = Event.find(params[:id])
    data = {
      event_id: event.id,
      title: event.title,
      author_id: event.author_id,
      url: event_path(event)
    }.to_json

    respond_to do |format|
      format.json {render json: data}
    end
  end


  def moderation_flag
    event = Event.find_by(id: params[:id])
    event.moderation_flag = !event.moderation_flag
    event.save
    redirect_to :back, notice: t('notice.operaction_successfull')
  end


  def set_view
    @view = (params[:view] == "minimal") ? "minimal" : "default"
  end

  def vote
    logger.debug "-----------" + @event.id.to_s
    logger.debug "-----------" + @current_user.username.to_s
    logger.debug "-----------" + params[:value].to_s
    @event.register_vote(current_user, params[:value])
    set_event_votes(@event)
  end

  def unmark_featured
    @event.update_attribute(:featured_at, nil)
    redirect_to request.query_parameters.merge(action: :index)
  end

  def mark_featured
    @event.update_attribute(:featured_at, Time.current)
    redirect_to request.query_parameters.merge(action: :index)
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def send_notification_tags(resource)
    send_notification_for_tags(resource)
  end

  def event_params
    if current_user.administrator? || current_user.moderator?
      moderation_entity_v = 1
    else
      moderation_entity_v = 2
    end
    params.require(:event).permit(:title, :description, :tag_list, :start_event, :end_event, :event_type_id, :all_day_event, #:color,
                                  :skip_map,
                                  :social_access, #Identificazione Social
                                  social_content_attributes: [:social_access], #Identificazione Social
                                  event_slots_attributes: [:id, :start_event, :end_event, :_destroy],
                                  images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                  documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                  map_location_attributes: [:latitude, :longitude, :zoom]).merge(moderation_entity: moderation_entity_v)
  end

  def destroy_map_location_association
    map_location = params[:event][:map_location_attributes]
    skip_map = params[:event][:skip_map]
    if skip_map == "1" || (map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?)
      MapLocation.destroy(map_location[:id])
    end
  end

end
