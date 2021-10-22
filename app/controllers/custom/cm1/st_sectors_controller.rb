class StSectorsController < ApplicationController

  include Search
  include ServiceFlags
  #include CommentableActions
  include FlagActions
  include NotificationsHelper

  before_action :parse_search_terms, only: :index
  before_action :destroy_map_location_association, only: :update

  #add settori breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.sectors"), :sectors_path

  load_and_authorize_resource :st_sector
  skip_authorization_check only: :json_data


  def index

    logger.debug "------------ index_customization " + params[:sector_type].to_s

    if params[:sector_type].present?
      @sector_type = params[:sector_type]
    elsif params[:advanced_search].present? && params[:advanced_search][:sector_type].present?
      @sector_type = params[:advanced_search][:sector_type]
    end

    if params[:sector_type].present?
      @resources = resource_model.sector_type(params[:sector_type])
    else
      @resources = resource_model.all
    end

    @resources = @resources.search(@search_terms) if @search_terms.present?
    @resources = @advanced_search_terms.present? ? @resources.filter(@advanced_search_terms) : @resources
    @resources = @resources.page(params[:page]).per(3)
    @st_sectors = @resources


  end

  def update
    @st_sector = StSector.find(params[:id])
    if @st_sector.update(st_sector_params)
      @st_sector.status_edit = nil
      @st_sector.save
      st_sector = StSector.where(sector_id: @st_sector.sector_id).where(state: 4).where(status_edit: 1).first
      unless st_sector.nil?
        st_sector.status_edit = nil
        st_sector.state = 11
        st_sector.save
      end
      @sector = Sector.find(@st_sector.sector_id)
      redirect_to sector_path(@sector, st: @st_sector.id), notice: I18n.t('flash.actions.update.st_sector')
    end
  end

  def json_data
    st_sector = StSector.find(params[:id])
    data = {
        st_sector_id: st_sector.id,
        title: st_sector.name,
        url: '#'
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end

  def load_data
    @st_sector = StSector.unscoped.find(params[:id])
  end

  def add_notification(st_sector)
    notifiable = st_sector
    notifiable_admin = User.administrators.where(pon_id: notifiable.user.pon_id)
    notifiable_admin.each do |user|
      Notification.add(user, notifiable)
    end

    notifiable_admin = User.moderators.where(pon_id: notifiable.user.pon_id)
    notifiable_admin.each do |user|
      Notification.add(user, notifiable)
    end

  end


  private

  def st_sector_params
    params.require(:st_sector).permit(:name, :vat_code, :address, :legal_representative, :phone_number, :email,
                                      :skip_map,
                                      :note, :description, :sector_type_id, :cf_rappr_legale, :terms_of_service, :user_id,
                                      sector_type_attributes: [:id, :name],
                                      images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      map_location_attributes: [:latitude, :longitude, :zoom]).merge(pon_id: User.pon_id)
    #.merge(hidden_at: hidden_at_v, flags_count: flags_count_v, ignored_flag_at: nil)
  end

  def send_notification_tags(resource)
    send_notification_for_tags(resource)
  end

  def valid_retired_params?
    @st_sector.errors.add(:retired_reason, I18n.t('errors.messages.blank')) if params[:st_sector][:retired_reason].blank?
    @st_sector.errors.add(:retired_explanation, I18n.t('errors.messages.blank')) if params[:st_sector][:retired_explanation].blank?
    @st_sector.errors.empty?
  end

  def resource_model
    StSector
  end

=begin
  def destroy_map_location_association
    map_location = params[:st_sector][:map_location_attributes]
    skip_map =params[:st_sector][:skip_map]
    if skip_map == "1" and map_location[:id].present?
      MapLocation.destroy(map_location[:id])
      params[:st_sector][:map_location_attributes][:id] = ""
      params[:st_sector][:map_location_attributes][:latitude] = ""
      params[:st_sector][:map_location_attributes][:longitude] = ""
      params[:st_sector][:map_location_attributes][:zoom] = ""
    end
  end
=end

  def destroy_map_location_association
    map_location = params[:st_sector][:map_location_attributes]
    skip_map = params[:st_sector][:skip_map]
    if skip_map == "1" || (map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?)
      MapLocation.destroy(map_location[:id])
    end
  end

end
