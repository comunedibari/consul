class AssetsController < ApplicationController
  include ServiceFlags
  #include CommentableActions
  include FlagActions
  include NotificationsHelper
  include Search

  include Gamification
  gamification :Asset


  service_flag :assets
  #before_action :parse_tag_filter, only: :index
  before_action :authenticate_user!, except: [:index, :show, :map, :summary, :json_data, :large_map] #miamesso summary
  before_action :set_view, only: :index
  before_action :destroy_map_location_association, only: :update
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :load_data, only: [ :edit, :update, :show]
  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary] #miaaa
  before_action :load_tag_cloud

  skip_authorization_check only: :json_data

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders ->(c) { Asset.assets_orders(c.current_user) }, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  load_and_authorize_resource
  helper_method :resource_model, :resource_name
  respond_to :html, :js


  # add prenotazioni breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.assets"), :assets_path

  def map
    super
  end

  def large_map
    @assets=@assets.by_user_pon
  end

  def index
    @assets = Asset.by_user_pon

    @tot_resources = @assets.count


    @assets = @assets.search(@search_terms) if @search_terms.present?
    @assets = @advanced_search_terms.present? ? @assets.filter(@advanced_search_terms) : @assets
    @assets = @assets.tagged_with(@tag_filter) if @tag_filter

    @assets = @assets.page(params[:page]).sort_by_newest
  end

  # def index_customization
  #   @featured_assets = @assets.featured
  # end


  def show
    if @asset.schedule.to_hash[:rrules].count > 0
      occurences = @asset.schedule.occurrences_between(Date.current,Date.current+6.months)
      #reservation = @asset.bookings
      reservation = @asset.bookings.where("time_start > ?",(Date.current - 1.days).end_of_day)
      data = all_data_for_calendar(occurences,reservation)
    else
      data = Array.new
    end

    #super
    load_data
    #@related_contents = Kaminari.paginate_array(@asset.relationed_contents).page(params[:page]).per(5)
    redirect_to asset_path(@asset), status: :moved_permanently if request.path != asset_path(@asset)

    respond_to do |format|
      format.json { render json: data.to_json }
      format.html
    end

  end

  def social_flag
    @asset = Asset.find_by(id: params[:id])
    @asset.social_content.social_access = !@asset.social_content.social_access
    @asset.social_content.save
    @asset.touch

    redirect_to :back, notice: t('notice.operaction_successfull')
  end

  def  moderation_flag
    asset = Asset.find_by(id: params[:id])
    asset.moderation_flag = !asset.moderation_flag
    asset.save
    redirect_to :back, notice: t('notice.operaction_successfull')
  end



  def create
    @asset = Asset.new(asset_params.merge(author: current_user,pon_id: current_user.pon_id))
    if @asset.save
      #per creare il sectorable
      if asset_params[:sector_id].present? and asset_params[:sector_id].to_i > 0
        sector = Sector.find(asset_params[:sector_id].to_i)
        SectorContent.create(sectorable: @asset, sector: sector )
      end

      #add geolocation to proposal if exists user coords
      if current_user.administrator? || current_user.moderator?
        self.action_attribute = "approved"
        redirect_to share_asset_path(@asset), notice: I18n.t('flash.actions.create.asset')
        send_notification_tags(@asset)
      else
        redirect_to user_path(current_user), notice: I18n.t('flash.actions.create.asset_in_approval')
      end


    else
      render :new
    end
  end

  def edit
    super
    @asset.sector_id =  @asset.sector_content.present? ? @asset.sector_content.sector.id : nil
  end

  def update
    super
    if @asset.sector_content.present?
      @asset.sector_content.destroy
    end
    if asset_params[:sector_id].present? and asset_params[:sector_id].to_i > 0
      sector = Sector.find(asset_params[:sector_id].to_i)
      SectorContent.create(sectorable: @asset, sector: sector )
    end

  end

  def load_tag_cloud
    @tag_cloud = tag_cloud
  end

  def vote

    @asset.register_vote(current_user, params[:value])
    set_asset_votes(@asset)
    #gamification params
    if @asset.votes.where(voter_id: current_user.id).present?
     self.action_attribute = "no_action"
    end

    if params[:value] == "yes"
      self.insert_user_action(self.action_service, @asset.author,"support")
    end
  end



  def unmark_featured
    @asset.update_attribute(:featured_at, nil)
    redirect_to request.query_parameters.merge(action: :index)
  end

  def mark_featured
    @asset.update_attribute(:featured_at, Time.current)
    redirect_to request.query_parameters.merge(action: :index)
  end

  def json_data
    asset =  Asset.find(params[:id])
    data = {
      asset_id: asset.id,
      title: asset.name,
      author_id: asset.author_id,
      url: asset_path(asset)
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end

  private

    def tag_cloud
      TagCloud.new(resource_model, params[:search])
    end

    def send_notification_tags(resource)
      send_notification_for_tags(resource)
    end

    def asset_params
      if current_user.administrator? || current_user.moderator?
        moderation_entity_v=1
      else
        moderation_entity_v=2
      end
      params.require(:asset).permit(:title, :description, :summary, :external_url, :tag_list, :terms_of_service, :skip_map,
                                      :as_rappr_legale,:geozone_id,:sector_id,:sector_id,
                                      images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      sector_content_attributes: [:sector_id],
                                      map_location_attributes: [:latitude, :longitude, :zoom])#.merge(pon_id: User.pon_id)
                                      .merge(moderation_entity: moderation_entity_v)
    end

    def resource_model
      Asset
    end

    def set_view
      @view = (params[:view] == "minimal") ? "minimal" : "default"
    end

    def destroy_map_location_association
      map_location = params[:asset][:map_location_attributes]
      skip_map =params[:asset][:skip_map]
      if skip_map == "1" || (map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?)
        MapLocation.destroy(map_location[:id])
      end
    end



    def load_data
      @asset = Asset.find(params[:id])
    end

    def all_data_for_calendar occurrences,reservations

      date_format = '%Y-%m-%dT%H:%M'
      duration = @asset.schedule.duration
      all_data = Array.new

      occurrences.each do |slot|
        all_data.push({
        title: "",
        start: slot.strftime(date_format),
        end: (slot+@asset.schedule.duration).strftime(date_format),
        allDay: false,
        color: 'green',
        #user: 0,
        #backgroundColor: 'green',
        rendering: 'background'
        })
      end

      reservations.each do |reservation|
        time_end = reservation.time_end + 1.seconds
        if current_user and (current_user.id == reservation.booker_id or current_user.administrator?)
          all_data.push({
          title: "",
          start: reservation.time_start.strftime(date_format),
          end: time_end.strftime(date_format),
          allDay: false,
          color: 'red',
          id: reservation.id,
          #link:
          #rendering: 'background'
          })
        else
          all_data.push({
            title: "",
            start: reservation.time_start.strftime(date_format),
            end: time_end.strftime(date_format),
            allDay: false,
            color: 'red',
            rendering: 'background'
            })
          end
      end

      all_data
    end

    def load_categories
      @categories = ActsAsTaggableOn::Tag.category.order(:name)
    end
end
