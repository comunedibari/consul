class Moderation::SectorsController < Moderation::BaseController
  include ModerateActions
  include NotificationsHelper

  #include FeatureFlags
  #include ServiceFlags

  has_filters %w{new_adds change_requests cancellation_requests}, only: [:index, :show]
  has_orders %w{created_at}, only: :index

  #feature_flag :debates
  #service_flag  :sectors

  before_action :load_resources, only: [:index]
  before_action :check_params, only: [:outcome]
  before_action :check_sector_params, only: [:actions]
  before_action :load_data_for_show, only: :show

  load_and_authorize_resource

  def actions
    load_st_sector
    if ["false", "modify"].include? sector_params[:state] and (sector_params[:note].nil? or sector_params[:note].length < 1)
      redirect_to outcome_moderation_sector_path(@st_sector.sector_id, st: @st_sector.id, approved: sector_params[:state]), alert: "Campo Nota obbligatorio."
    else
      if @st_sector.nil?
        redirect_to moderation_sectors_path, alert: "Impossibile eseguire l'azione richiesta."
      else
        case StSector.states[@st_sector.state]
        when 1
          accept_st_sector
        when 5
          modify_st_sector
        when 8
          delete_st_sector
        end
      end
    end
  end

  def show

  end

  def outcome
    load_data
    if @st_sector.nil?
      redirect_to moderation_sectors_path, alert: "Impossibile eseguire l'azione richiesta."
    end
  end

  private

  def load_resources
    @resources = resource_model.where("state in (1,5,8)").by_user_pon
  end

  def resource_model
    StSector
  end

  def sector_params
    params.require(:sector).permit(
      :state,
      :note,
      :st
    )
  end

  def st_sector_to_sector
    @sector.name = @st_sector.name
    @sector.vat_code = @st_sector.vat_code
    @sector.address = @st_sector.address
    @sector.legal_representative = @st_sector.legal_representative
    @sector.phone_number = @st_sector.phone_number
    @sector.email = @st_sector.email
    @sector.description = @st_sector.description
    @sector.sector_type_id = @st_sector.sector_type_id

    if @st_sector.map_location
      if @sector.map_location
        @sector.map_location.latitude = @st_sector.map_location.latitude
        @sector.map_location.longitude = @st_sector.map_location.longitude
        @sector.map_location.zoom = @st_sector.map_location.zoom
      else
        @sector.map_location = @st_sector.map_location.dup
      end
    else
      if @sector.map_location.present?
        #@sector.map_location.destroy
        MapLocation.destroy(@sector.map_location.id)
      end
      @sector.skip_map = "1"
    end

    if @sector.save!

      if @sector.images.count > 0
        image = @sector.images.first
        path = image.attachment.path.split("/original").first
        FileUtils.remove_dir(path)
        image.destroy
      end

      if @sector.documents.count > 0
        @sector.documents.each do |document|
          path = document.attachment.path.split("/original").first
          FileUtils.remove_dir(path)
          document.destroy
        end
      end

      if @st_sector.images.count > 0
        image = @st_sector.images.first
        file = image.dup
        file.imageable_id = @sector.id
        file.imageable_type = "Sector"
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

      if @st_sector.documents.count > 0
        @st_sector.documents.each do |document|
          file = document.dup
          file.documentable_id = @sector.id
          file.documentable_type = "Sector"
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

  def accept_st_sector
    @st_sector.note = sector_params[:note]
    if sector_params[:state] == "true"
      @st_sector.state = 2
      @sector.visible = true
      @st_sector.save
      @sector.save
      #notifica abilitata
      add_notification @st_sector
      redirect_to moderation_sectors_path, notice: "Inserimento nuova Associazione approvato con successo."
    elsif sector_params[:state] == "modify"
      @st_sector.state = 4
      @st_sector.save
      #notifica abilitata
      add_notification @st_sector
      redirect_to moderation_sectors_path, notice: "Richiesta integrazione inviata con successo."
    elsif sector_params[:state] == "false"
      @st_sector.state = 3
      @st_sector.save
      #notifica abilitata
      add_notification @st_sector
      redirect_to moderation_sectors_path, notice: "Inserimento nuova Associazione non approvato."
    end
  end

  def modify_st_sector
    @st_sector.note = sector_params[:note]
    if sector_params[:state] == "true"
      st_sector_to_sector
      @st_sector.state = 6
      @st_sector.save
      #notifica abilitata
      add_notification @st_sector
      redirect_to moderation_sectors_path, notice: "Modifica Associazione approvata con successo."
    elsif sector_params[:state] == "modify"
      @st_sector.state = 4
      @st_sector.save
      #notifica abilitata
      add_notification @st_sector
      redirect_to moderation_sectors_path, notice: "Richiesta integrazione inviata con successo."
    elsif sector_params[:state] == "false"
      @st_sector.state = 7
      @st_sector.save
      #notifica abilitata
      add_notification @st_sector
      redirect_to moderation_sectors_path, notice: "Modifica Associazione non approvata."
    end
  end

  def delete_st_sector
    @st_sector.note = sector_params[:note]
    if sector_params[:state] == "true"
      clean_st_sector
      clean_sector
      @st_sector.state = 10
      @st_sector.save
      #notifica abilitata
      add_notification @st_sector
      redirect_to moderation_sectors_path, notice: "Richiesta cancellazione Associazione approvata con successo."
    elsif sector_params[:state] == "false"
      @st_sector.state = 9
      @st_sector.save
      #notifica abilitata
      add_notification @st_sector
      redirect_to moderation_sectors_path, notice: "Richiesta cancellazione Associazione non approvata."
    end
  end

  def clean_sector

    if @sector.map_location.present?
      @sector.map_location.destroy
    end

    if @sector.images.count > 0
      image = @sector.images.first
      path = image.attachment.path.split("/original").first
      FileUtils.remove_dir(path)
      image.destroy
    end

    if @sector.documents.count > 0
      @sector.documents.each do |document|
        path = document.attachment.path.split("/original").first
        FileUtils.remove_dir(path)
        document.destroy
      end
    end

    @sector.name = "Associazione sconosciuta"
    @sector.vat_code = "-"
    @sector.address = "-"
    @sector.legal_representative = ""
    @sector.phone_number = ""
    @sector.email = ""
    @sector.cf_rappr_legale = ""
    @sector.tsv = ""
    @sector.user_id = nil
    @sector.description = ""
    @sector.note = ""
    @sector.visible = false
    @sector.save
  end

  def clean_st_sector
    st_sectors = StSector.where(sector_id: @sector.id)
    st_sectors.each do |st_sector|

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

      st_sector.name = "Associazione sconosciuta"
      st_sector.vat_code = ""
      st_sector.address = ""
      st_sector.legal_representative = ""
      st_sector.phone_number = ""
      st_sector.email = ""
      st_sector.cf_rappr_legale = ""
      st_sector.tsv = ""
      st_sector.user_id = nil
      st_sector.description = ""
      st_sector.note = ""
      st_sector.save
    end
  end

  def check_params
    unless ["true", "false", "modify"].include? params[:approved]
      redirect_to moderation_sectors_path, alert: "Impossibile eseguire l'azione richiesta."
    end
  end

  def check_sector_params
    unless ["true", "false", "modify"].include? sector_params[:state]
      redirect_to moderation_sectors_path, alert: "Impossibile eseguire l'azione richiesta."
    end
  end

  def load_data
    @sector = Sector.unscoped.find(params[:id])
    @st_sector = StSector.where(id: params[:st]).where(sector_id: @sector.id).where(state: [1, 5, 8]).first
    @st_sectors = StSector.where(sector_id: @sector.id).order(:created_at)
  end

  def load_data_for_show
    @sector = Sector.unscoped.find(params[:id])
    @st_sector = StSector.where(id: params[:st]).where(sector_id: @sector.id).first
    @st_sectors = StSector.where(sector_id: @sector.id).order(:created_at)
  end

  def load_st_sector
    @st_sector = StSector.where(id: sector_params[:st]).where(sector_id: @sector.id).where(state: [1, 5, 8]).first
  end

  def add_notification(st_sector)
    notifiable = st_sector
    st_sector_id = st_sector.user_id
    notifiable_user = User.find(st_sector_id)
    Notification.add(notifiable_user, notifiable)
    ModerationActionNotifier.new(moderable: st_sector,
                                 notification_html: make_st_sector_mail_notifications(st_sector)).process
  end

end
