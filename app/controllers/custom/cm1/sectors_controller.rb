class SectorsController < ApplicationController

  include Search
  include ServiceFlags
  #include CommentableActions
  include FlagActions
  include NotificationsHelper

  before_action :parse_search_terms, only: :index
  before_action :load_data, only: :show

  #add settori breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.sectors"), :sectors_path

  load_and_authorize_resource :sector
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
    @resources = @resources.where(visible: true).page(params[:page]).per(9)
    @sectors = @resources

  end

  def create
    @sector = Sector.new(sector_params.merge(user_id: current_user.id, legal_representative: current_user.name, cf_rappr_legale: current_user.cod_fiscale, pon_id: session[:pon_id], visible: false))
    #@st_sector = StSector.new(sector_params.merge(user_id: current_user.id, pon_id: session[:pon_id], request: 1, state: 1))
    if @sector.save
      #add geolocation to proposal if exists user coords
      if current_user.administrator? || current_user.moderator?
        redirect_to share_sector_path(@sector), notice: I18n.t('flash.actions.create.sector')
        #send_notification_tags(@sector)
      else
        #add_notification @sector
        redirect_to share_sector_path(@sector), notice: I18n.t('flash.actions.create.sector_in_approval')
      end

    else
      render :new
    end
  end

  def share
    crea_st_sector
  end

  def edit
    @sector = Sector.find(params[:id])
    id = params[:id]
    clean_edit_st_sector
    if !editable?
      redirect_to sector_path(@sector), notice: I18n.t('flash.actions.update.error_edit')
    else
      if !duplica_st_sector
        redirect_to sector_path(id), notice: I18n.t('flash.actions.update.error_edit_a')
      else
        @sector.skip_map = nil
      end
    end
  end

  def editable?
    id = StSector.where(sector_id: @sector.id).maximum(:id)
    st_sector = StSector.where(id: id).first
    if [2, 4, 6, 7, 9, 13].include? StSector.states[st_sector.state] and (st_sector.status_edit.nil? || st_sector.status_edit == "")
      true
    else
      false
    end
  end

  def update
    @sector.update(sector_params)
  end

  def show

  end

  def clean_st
    if params[:st].present?
      st_sector = StSector.find(params[:st])

      if st_sector.map_location.present?
        st_sector.map_location.destroy
      end

      if st_sector.images.count > 0
        image = st_sector.images.first
        path = image.attachment.path.split("/original").first
        FileUtils.remove_dir(path)
        image.destroy
      end

      if st_sector.documents.count > 0
        st_sector.documents.each do |document|
          path = document.attachment.path.split("/original").first
          FileUtils.remove_dir(path)
          document.destroy
        end
      end

      st_sector.destroy
    end
    redirect_to sector_path(@sector)
  end

  def remove_st(id)

    st_sector = StSector.find(id)

    if st_sector.map_location.present?
      st_sector.map_location.destroy
    end

    if st_sector.images.count > 0
      image = st_sector.images.first
      path = image.attachment.path.split("/original").first
      FileUtils.remove_dir(path)
      image.destroy
    end

    if st_sector.documents.count > 0
      st_sector.documents.each do |document|
        path = document.attachment.path.split("/original").first
        FileUtils.remove_dir(path)
        document.destroy
      end
    end

    st_sector.destroy

  end

  def json_data
    sector = Sector.find(params[:id])
    data = {
      sector_id: sector.id,
      title: sector.name,
      url: '#'
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end

  def delete
    id = @sector.id
    if !editable?
      redirect_to sector_path(@sector), notice: I18n.t('flash.actions.destroy.error_request')
    elsif !duplica_st_sector
      redirect_to sector_path(id), notice: I18n.t('flash.actions.destroy.error_request')
    elsif @sector.state = 8
      @sector.request = 3
      @sector.status_edit = ""
      @sector.save
      redirect_to sector_path(@sector.sector_id, st: @sector.id), notice: t("flash.actions.destroy.st_sector_in_approval")
    end
  end

=begin
  def add_notification(sector)
    notifiable = sector
    notifiable_admin = User.administrators.where(pon_id: notifiable.user.pon_id)
    notifiable_admin.each do |user|
      Notification.add(user, notifiable)
    end

    notifiable_admin = User.moderators.where(pon_id: notifiable.user.pon_id)
    notifiable_admin.each do |user|
      Notification.add(user, notifiable)
    end

  end
=end

  private

  def sector_params

    params.require(:sector).permit(:name, :vat_code, :address, :legal_representative, :phone_number, :email,
                                   :skip_map,
                                   :note, :description, :sector_type_id, :cf_rappr_legale, :terms_of_service, :user_id,
                                   sector_type_attributes: [:id, :name],
                                   images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                   documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                   map_location_attributes: [:latitude, :longitude, :zoom]).merge(pon_id: User.pon_id)
  end

  def crea_st_sector

    @st_sector = StSector.new
    @st_sector.name = @sector.name
    @st_sector.vat_code = @sector.vat_code
    @st_sector.address = @sector.address
    @st_sector.legal_representative = @sector.legal_representative
    @st_sector.phone_number = @sector.phone_number
    @st_sector.email = @sector.email
    @st_sector.description = @sector.description
    @st_sector.sector_type_id = @sector.sector_type_id
    @st_sector.cf_rappr_legale = @sector.cf_rappr_legale
    @st_sector.user_id = @sector.user_id
    @st_sector.terms_of_service = "1"
    @st_sector.pon_id = @sector.pon_id
    @st_sector.request = 1
    @st_sector.state = 1
    @st_sector.sector_id = @sector.id

    if @sector.map_location
      @st_sector.map_location = @sector.map_location.dup
    else
      @st_sector.skip_map = "1"
    end

    if @st_sector.save!

      if @sector.images.count > 0
        image = @sector.images.first
        file = image.dup
        file.imageable_id = @st_sector.id
        file.imageable_type = "StSector"
        file.save

        src = image.attachment.path
        dest = file.attachment.path
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(src, dest)

        image.attachment.styles.keys.each do |key|
          src = image.attachment.path(key)
          dest = file.attachment.path(key)
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp(src, dest)
        end
      end

      if @sector.documents.count > 0
        @sector.documents.each do |document|
          file = document.dup
          file.documentable_id = @st_sector.id
          file.documentable_type = "StSector"
          file.save

          src = document.attachment.path
          dest = file.attachment.path
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp(src, dest)

        end
      end

      true
    else
      false
    end

  end

  def find_sector_to_modify
    id = StSector.where(sector_id: @sector.id).where(state: [2, 4, 6, 13]).maximum(:id)
    st_sector = StSector.where(id: id).first
    st_sector
  end

  def duplica_st_sector
    st_sector = find_sector_to_modify
    @sector = st_sector.dup
    @sector.note = ""
    @sector.terms_of_service = "1"
    if st_sector.map_location
      @sector.map_location = st_sector.map_location.dup
    else
      @sector.skip_map = "1"
    end

    @sector.request = 2
    @sector.state = 5
    @sector.status_edit = 2

    if @sector.save!
      if st_sector.state == 4
        st_sector.status_edit = 1
        st_sector.save
      end
      #ricopia le vecchie immagini e documenti di @debate, duplicando i file. Per le immagini venogono duplicati tutti gli style
      if st_sector.images.count > 0
        image = st_sector.images.first
        file = image.dup
        file.imageable_id = @sector.id
        file.save

        src = image.attachment.path
        dest = file.attachment.path
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(src, dest)

        image.attachment.styles.keys.each do |key|
          src = image.attachment.path(key)
          dest = file.attachment.path(key)
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp(src, dest)
        end
      end

      if st_sector.documents.count > 0
        st_sector.documents.each do |document|
          file = document.dup
          file.documentable_id = @sector.id
          file.save

          src = document.attachment.path
          dest = file.attachment.path
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp(src, dest)
        end
      end

      true

    else

      false

    end
  end

  def valid_retired_params?
    @sector.errors.add(:retired_reason, I18n.t('errors.messages.blank')) if params[:sector][:retired_reason].blank?
    @sector.errors.add(:retired_explanation, I18n.t('errors.messages.blank')) if params[:sector][:retired_explanation].blank?
    @sector.errors.empty?
  end

  def resource_model
    Sector
  end

  def find_sector_to_show
    id = StSector.where(sector_id: @sector.id).where(state: [2, 6, 13]).maximum(:id)
    st_sector = StSector.where(id: id).first
    st_sector
  end

  def clean_edit_st_sector
    st_sectors = StSector.where(sector_id: @sector.id).where(status_edit: [1, 2])
    st_sectors.each do |st_sector|
      if st_sector.status_edit == 1 and StSector.states[st_sector.state] == 4
        st_sector.status_edit = nil
        st_sector.save
      elsif st_sector.status_edit == 2 and StSector.states[st_sector.state] == 5
        remove_st(st_sector.id)
      end
    end
  end

  def load_data
    @sector = Sector.unscoped.find(params[:id])
    if current_user.present?
      if @sector.user_id == current_user.id || current_user.administrator? || current_user.moderator?
        clean_edit_st_sector
        @st_sectors = StSector.where(sector_id: @sector.id).order(:created_at)
        if params[:st].present?
          @sector = StSector.find(params[:st])
        else
          @sector = find_sector_to_show
          if @sector == nil
            @sector = StSector.where(sector_id: params[:id]).where(state: [1, 3, 4]).first
          end
        end
      else
        id = StSector.where(sector_id: @sector.id).where(state: [2, 6, 13]).maximum(:id)
        @sector = StSector.where(id: id).first
      end
    end
  end

end
