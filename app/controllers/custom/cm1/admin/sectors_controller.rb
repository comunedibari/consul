class Admin::SectorsController < Admin::BaseController
  include Search

  before_action :parse_search_terms, only: :index

  before_action :set_sector, only: [:rem_relation, :relation, :update]

  load_and_authorize_resource :sector, except: :create

  require 'fileutils'

  def index
    @resources = resource_model.all
    @resources = @resources.search(@search_terms) if @search_terms.present?
    @resources = @advanced_search_terms.present? ? @resources.filter(@advanced_search_terms) : @resources
    @resources = @resources.where(visible: true).page(params[:page]).per(5)
    @sectors = @resources

    if params[:search]
      ids = Identity.where("provider = 'openam'").pluck(:user_id)
      @users = User.by_username_email_or_document_number(params[:search]).where(id: ids) if params[:search]
      #@users = @users.by_user_pon
      @users = @users.page(params[:page]).per(4)
      respond_to do |format|
        format.html
        format.js
      end
    end
  end

  def new

  end

  def search
    @users = User.search(params[:name_or_email])
                 .includes(:sector)
                 .page(params[:page])
                 .for_render
  end

  def edit
    @sector = Sector.find(params[:id])
    @@sector = Sector.find(params[:id])
    #if !defined? @@sector
    #  @@sector = Sector.find(params[:id])
    #end
    #@users = User.where(id: @sector.user_id)
    @users = User.where(id: -1)
    @users = @users.page(params[:page])
    respond_to do |format|
      format.html
      format.js
    end

  end

  def create
    trueFormat = false
    if !params[:upload].nil?
      name = params[:upload][:file].original_filename
      case File.extname(name)
      when ".xls"
        trueFormat = true
      when ".xlsx"
        trueFormat = true
      end
      if trueFormat
        path = File.join('app', 'public', 'upload', name)
        fExt = File.extname(name)
        name = File.basename(name, ".*")
        File.open(path, "wb") { |f| f.write(params[:upload][:file].read) }
        newName = name + "_" + params[:id_sector_type] + "_" + Time.now.to_i.to_s + fExt
        newPath = File.join('app', 'public', 'upload', newName)
        File.rename(path, newPath)
        sector_type_to_save = params[:id_sector_type]
        DecodeXlsSectorsJob.perform_later newName, current_user, sector_type_to_save
        flash[:notice] = t("admin.third_sector.index.uploaded")
        redirect_to "/amministrazione/terzo_settore"
      else
        flash[:notice] = t("admin.third_sector.index.wrong_format")
        redirect_to "/amministrazione/terzo_settore"
      end
    else
      flash[:notice] = t("admin.third_sector.index.wrong_format")
      redirect_to "/amministrazione/terzo_settore"
    end
  end

  def relation    
    if params[:sector].present? and (!params[:sector][:legal_representative].present? or !params[:sector][:cf_rappr_legale].present?)
      redirect_to edit_admin_sector_path(@sector.id), alert: "Compilare campi obbligatori"
    else
      rem_relation
      crea_rel_sector
    end
  end

  def rem_relation
    rem_rel_sector
    #redirect_to edit_admin_sector_path(@sector.id)
  end

  def update
    if @sector.update()
      redirect_to admin_sectors_path
    else
      render :edit
    end
  end

  def downloadxlsx

    send_file(
      "#{Rails.root}/app/public/upload/template/template_Terzo_Settore.xlsx",
      filename: "template_Terzo_Settore.xlsx",
      type: "application/xlsx"
    )
  end

  private

  def sector_params

    params.require(:sector).permit(:name, :vat_code, :address, :legal_rapresentative, :phone_number, :email,
                                   :skip_map,
                                   user_attributes: [:id],
                                   sector_type_attributes: [:id, :name]
    )

  end

  def show
    @sectors = Sector.find(params[:id])
  end

  def crea_rel_sector
    if params[:id].to_i == @sector.id and params[:sector].present?
      if params[:sector][:legal_representative].present? and params[:sector][:cf_rappr_legale].present?
        cf_user = User.where(cod_fiscale: params[:sector][:cf_rappr_legale]).first
        @sector.cf_rappr_legale = params[:sector][:cf_rappr_legale]
        @sector.legal_representative = cf_user.nil? ? params[:sector][:legal_representative] : cf_user.username
        @sector.user_id = cf_user.nil? ? nil : cf_user.id
        @sector.save
        allinea_st_sector_to_add
        redirect_to edit_admin_sector_path(@sector.id)
      else
        redirect_to edit_admin_sector_path(@sector.id), alert: "Compilare campi obbligatori"
      end
    else
      user_sel = User.find(params[:id])
      @sector.crea_relation_sector(user_sel)
      allinea_st_sector_to_add
      redirect_to edit_admin_sector_path(@sector.id)
    end
  end

  def rem_rel_sector
    clean_edit_st_sector
    duplica_st_sector_to_clean
    @sector.del_relation_sector
    #redirect_to edit_admin_sector_path(@sector.id)

  end

  def set_sector
    @sector = Sector.find(@@sector.id)
    logger.debug "------------" + @@sector.id.to_s
  end

  def resource_model
    Sector
  end

  def find_sector_to_modify
    #id = StSector.where(sector_id: @sector.id).where(state: [2, 6]).maximum(:id)
    id1 = StSector.where(sector_id: @sector.id).where(state: [2, 6]).maximum(:id)
    id2 = StSector.where(sector_id: @sector.id).where(state: 4).maximum(:id)

    if !id2.nil? and id2 > id1
      id3 = StSector.where(sector_id: @sector.id).where(state: 7).maximum(:id)
      if !id3.nil? and id3 > id2
        id = id1
      else
        id = id2
      end
    else
      id = id1
    end
    st_sector = StSector.where(id: id).first
    st_sector
  end

  def duplica_st_sector_to_clean
    st_sector = find_sector_to_modify
    st_sector_copy = st_sector.dup
    st_sector_copy.note = ""
    st_sector_copy.terms_of_service = "1"
    if st_sector.map_location
      st_sector_copy.map_location = st_sector.map_location.dup
    else
      st_sector_copy.skip_map = "1"
    end

    st_sector_copy.request = 4
    st_sector_copy.state = 12

    st_sector_copy.user_id = nil
    st_sector_copy.cf_rappr_legale = ""
    st_sector_copy.legal_representative = ""

    if st_sector_copy.save!

      #ricopia le vecchie immagini e documenti di @debate, duplicando i file. Per le immagini venogono duplicati tutti gli style
      if st_sector.images.count > 0
        image = st_sector.images.first
        file = image.dup
        file.imageable_id = st_sector_copy.id
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
          file.documentable_id = st_sector_copy.id
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

    st_sectors = StSector.where(sector_id: @sector.id)
    st_sectors.each do |st_s|
      st_s.user_id = nil
      st_s.save
    end
  end

  def allinea_st_sector_to_add
    st_sector = StSector.where(sector_id: @sector.id).where(state: 12).first

    st_sector.request = 4
    st_sector.state = 13

    st_sector.user_id = @sector.user_id
    st_sector.cf_rappr_legale = @sector.cf_rappr_legale
    st_sector.legal_representative = @sector.legal_representative

    st_sector.save

    st_sectors = StSector.where(sector_id: @sector.id)
    st_sectors.each do |st_s|
      st_s.user_id = @sector.user_id
      st_s.save
    end
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
end
