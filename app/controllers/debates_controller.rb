class DebatesController < ApplicationController
  include ServiceFlags
  include CommentableActions
  include FlagActions
  include NotificationsHelper

  include Gamification
  gamification :Debate


  service_flag :debates
  before_action :parse_tag_filter, only: :index
  before_action :authenticate_user!, except: [:index, :show, :map, :summary, :json_data, :large_map] #miamesso summary
  before_action :set_view, only: :index
  before_action :destroy_map_location_association, only: :update
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :load_data, only: [ :edit, :update, :show]
  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary] #miaaa

  skip_authorization_check only: :json_data

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders ->(c) { Debate.debates_orders(c.current_user) }, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  load_and_authorize_resource
  helper_method :resource_model, :resource_name
  respond_to :html, :js

  #add debates breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.debates"), :debates_path

  def map
    super
  end

  def large_map
    @debates=@debates.by_user_pon
  end

  def index_customization
    @featured_debates = @debates.featured
  end


  def show
    Rails.logger.info request.inspect
    super
    load_data
    @related_contents = Kaminari.paginate_array(@debate.relationed_contents).page(params[:page]).per(5)
    redirect_to debate_path(@debate), status: :moved_permanently if request.path != debate_path(@debate)
  end

  def moderation_flag
    debate = Debate.find_by(id: params[:id])
    debate.moderation_flag = !debate.moderation_flag
    debate.save
    redirect_to :back, notice: t('notice.operaction_successfull')
  end

  def social_flag
    @debate = Debate.find_by(id: params[:id])
    @debate.social_content.social_access = !@debate.social_content.social_access
    @debate.social_content.save
    @debate.touch
    redirect_to :back, notice: t('notice.operaction_successfull')
  end


  def create
    #@debate = Debate.new(debate_params.merge(author: current_user,pon_id: current_user.pon_id))
    @debate = Debate.new(debate_params.merge(author: current_user,pon_id: session[:pon_id]))
    if @debate.save
      if debate_params[:sector_id].present? and debate_params[:sector_id].to_i > 0
        sector = Sector.find(debate_params[:sector_id].to_i)
        SectorContent.create(sectorable: @debate, sector: sector )
      end



      if current_user.administrator?
        if params[:debate][:social_content][:social_access].to_i > 0
          SocialContent.create(sociable: @debate, social_access: true)
        else
          SocialContent.create(sociable: @debate, social_access: false)
        end
      else
        social_service = Setting.find_by(key: 'service_social.debates',pon_id: User.pon_id).value
        SocialContent.create(sociable: @debate, social_access: social_service)
      end


      #add geolocation to proposal if exists user coords
      if current_user.administrator? || current_user.moderator?
        self.action_attribute = "approved"
        redirect_to share_debate_path(@debate), notice: I18n.t('flash.actions.create.debate')
        send_notification_tags(@debate)
      else
        #add notification
        add_notification @debate
        redirect_to user_path(current_user), notice: I18n.t('flash.actions.create.debate_in_approval')
      end

    else
      render :new
    end
  end

  def edit
    super
    @debate.sector_id =  @debate.sector_content.present? ? @debate.sector_content.sector.id : nil
  end

  def update
    super
    if @debate.sector_content.present?
      @debate.sector_content.destroy
    end
    if debate_params[:sector_id].present? and debate_params[:sector_id].to_i > 0
      sector = Sector.find(debate_params[:sector_id].to_i)
      SectorContent.create(sectorable: @debate, sector: sector )
    end

    #--------------------------------------
      if current_user.provider == "openam" || current_user.administrator?

          if params[:debate][:social_content][:social_access].present?
            @social_content = SocialContent.where(sociable_type: 'Debate').where(sociable_id: @debate.id).first
            if params[:debate][:social_content][:social_access].to_i > 0
              @social_content.update_attribute(:social_access, true)
            else
              @social_content.update_attribute(:social_access, false)
            end
          end

      end



  end

  def add_notification(debate)
    notifiable = debate
    notifiable_admin = User.administrators.where(pon_id: notifiable.author.pon_id)
    notifiable_admin.each do |user|
      Notification.add(user, notifiable)
    end

    notifiable_admin = User.moderators.where(pon_id: notifiable.author.pon_id)
    notifiable_admin.each do |user|
      Notification.add(user, notifiable)
    end

  end

  def vote

    @debate.register_vote(current_user, params[:value])
    set_debate_votes(@debate)
    #gamification params
    if @debate.votes.where(voter_id: current_user.id).present?
     self.action_attribute = "0"
    end

    if params[:value] == "yes"
      self.insert_user_action(self.action_service, @debate.author,"support")
    end
  end



  def unmark_featured
    @debate.update_attribute(:featured_at, nil)
    redirect_to request.query_parameters.merge(action: :index)
  end

  def mark_featured
    @debate.update_attribute(:featured_at, Time.current)
    redirect_to request.query_parameters.merge(action: :index)
  end

  def json_data
    debate =  Debate.find(params[:id])
    data = {
      debate_id: debate.id,
      title: debate.title,
      author_id: debate.author_id,
      url: debate_path(debate)
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end

  private

    def send_notification_tags(resource)
      send_notification_for_tags(resource)
    end

    def debate_params
      if current_user.administrator? || current_user.moderator?
        moderation_entity_v=1
      else
        moderation_entity_v=2
      end
      params.require(:debate).permit(:title, :description, :summary, :external_url, :tag_list, :terms_of_service, :skip_map,
                                      :as_rappr_legale,:geozone_id,:sector_id,:social_access,
                                      images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      sector_content_attributes: [:sociable_id,:sociable_type,:sector_id],
                                      social_content_attributes: [:social_access],
                                      map_location_attributes: [:latitude, :longitude, :zoom])#.merge(pon_id: User.pon_id)
                                      .merge(moderation_entity: moderation_entity_v)
    end

    def resource_model
      Debate
    end

    def set_view
      @view = (params[:view] == "minimal") ? "minimal" : "default"
    end

  def destroy_map_location_association
    map_location = params[:debate][:map_location_attributes]
    skip_map =params[:debate][:skip_map]
    if skip_map == "1" || (map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?)
      MapLocation.destroy(map_location[:id])
    end
  end

    #add taggs to debates
    def summary
      @debates = Debate.for_summary
      @tag_cloud = tag_cloud
    end

    def load_data
      @debate = Debate.find(params[:id])
      if !@debate.load_entity?(current_user)
        raise CanCan::AccessDenied
      end
    end

end
