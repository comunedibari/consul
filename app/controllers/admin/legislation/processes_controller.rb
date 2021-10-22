class Admin::Legislation::ProcessesController < Admin::Legislation::BaseController
  has_filters %w{opens next past all}, only: :index
  before_action :destroy_map_location_association, only: :update
  before_action :load_process, only: [:edit, :update, :show, :debate, :proposal, :result_publication, :allegations, :draft_publication]
  before_action :load_categories, only: [:index, :new, :create, :edit, :filter_by_typology]
  load_and_authorize_resource :process, class: "Legislation::Process"
  include CommentableActions

  def edit
    super
    @process.sector_id = @process.sector_content.present? ? @process.sector_content.sector.id : nil
  end

  def new
    #@process = Legislation::Process.new
  end

  def index
    #mi prendo tutti i process dalla tabella processes che hanno process_type=1
    @processes = ::Legislation::Process.send(@current_filter).by_user_pon.where("process_type = 1").order('id DESC').page(params[:page])
  end

  def show
    render :edit
  end

  def create
    @process = ::Legislation::Process.new(process_params.merge(author: current_user, process_type: 1, pon_id: current_user.pon_id))
    #al momento in cui faccio "nuovo progetto" sto nella "new" ..quindi compilo tutti i campi..
    #e quindi al momento del salvataggio sto nella "create" se il salvataggio su db è andato a buon fine
    if @process.save
      sector = Sector.find(process_params[:sector_id].to_i)
      if process_params[:as_rappr_legale].to_i > 0 and process_params[:sector_id].to_i > 0
        SectorContent.create(sectorable: @process, sector: sector)
      end
      #ti riporta alla pagina http://localhost:3000/legislation/processes
      link = legislation_process_path(@process).html_safe
      notice = t('admin.legislation.processes.create.notice', link: link)
      #mi reindirizza alla pagina http://localhost:3000/admin/legislation/processes/24/edit
      redirect_to edit_admin_legislation_process_path(@process), notice: notice
    else
      flash.now[:error] = t('admin.legislation.processes.create.error')
      #se non va bene con il "render" vado quà http://localhost:3000/admin/legislation/processes
      render :new
    end
  end

  def update
    #se l'aggiornamento dei parametri del process è andato a buon fine
    if @process.update(process_params)
      if process_params[:as_rappr_legale].to_i > 0 and process_params[:sector_id].to_i > 0
        SectorContent.create(sectorable: @process, sector_id: process_params[:sector_id].to_i)
      end
      set_tag_list
      set_in_moderation
      if current_user.administrator? || current_user.moderator?
        link = legislation_process_path(@process).html_safe
        redirect_to :back, notice: t('admin.legislation.processes.proposals.update.notice', link: link)
      else
        link = legislation_process_path(@process).html_safe
        redirect_to :back, notice: t('admin.legislation.processes.proposals.update.notice_user', link: link)
      end
    else
      flash.now[:error] = t('admin.legislation.processes.update.error')
      #altrimenti ritorno alla pagina di modifica
      render :edit
    end
  end

  def destroy
    @process = ::Legislation::Process.find(params[:id])
    @process.destroy
    notice = t('admin.legislation.processes.destroy.notice')
    redirect_to admin_legislation_processes_path, notice: notice
  end

  def load_process
    @process = ::Legislation::Process.by_user_pon.process_all_type.with_hidden.find(params[:id])
  end

  private

  def process_params

    if current_user.administrator? || current_user.moderator?
      moderation_entity_v = 1
    else
      moderation_entity_v = 2
    end

    params.require(:legislation_process).permit(
        :title,
        :summary,
        :description,
        :additional_info,
        :start_date,
        :end_date,
        :debate_start_date,
        :debate_end_date,
        :draft_publication_date,
        :allegations_start_date,
        :allegations_end_date,
        :proposals_phase_start_date,
        :proposals_phase_end_date,
        :result_publication_date,
        :debate_phase_enabled,
        :allegations_phase_enabled,
        :proposals_phase_enabled,
        :draft_publication_enabled,
        :result_publication_enabled,
        :published,
        :proposals_description,
        :skip_map,
        :geozone_id,
        :tag_list,
        :visible,
        :as_rappr_legale, :geozone_id,
        :sector_id,
        sector_content_attributes: [:sector_id],
        documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        map_location_attributes: [:latitude, :longitude, :zoom]
    )
        .merge(moderation_entity: moderation_entity_v)
  end

  def set_tag_list
    @process.set_tag_list_on(:customs, process_params[:custom_list])
    @process.save
  end


  def destroy_map_location_association
    map_location = params[:legislation_process][:map_location_attributes]
    if map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?
      MapLocation.destroy(map_location[:id])
    end
  end

  def destroy_sector_content_association
    sector_content = params[:legislation_process][:sector_content_attributes]
    if sector_content && (sector_content[:sector_id] && !sector_content[:id].blank?
    SectorContent.destroy(sector_content[:id]))
    end
  end
end
