class Legislation::ProcessesController < Legislation::BaseController
  include ServiceFlags
  include CommentableActions
  include FlagActions

  #service_flag :works
  before_action :load_data, only: [:edit, :update, :show, :debate, :proposal, :result_publication, :allegations, :details, :draft_publication, :sgap]
  has_filters %w{opens next past}, only: [:index, :oportunities]
  load_and_authorize_resource :process, class: "Legislation::Process"

  respond_to :html, :js

  has_orders ->(c) { Legislation::Process.processes_orders(c.current_user) }, only: :index

  skip_authorization_check only: [:json_data]

  before_action :parse_tag_filter, only: [:index, :oportunities]

  before_action :authenticate_user!, except: [:index, :show, :map, :summary, :json_data, :large_map, :debate, :proposal, :result_publication, :allegations, :details, :draft_publication, :sgap, :filter_by_typology]


  before_action :load_categories, only: [:index, :oportunities, :new, :create, :edit, :map, :summary]
  before_action :load_tag_cloud

  before_action :set_breadcrumb, except: [:index, :large_map, :filter_by_typology]

  def load_tag_cloud
    @tag_cloud = tag_cloud
  end

  def resource_model
    Legislation::Process
  end

  def process_type
    [1, 2, 3, 4, 5]
  end

  def resource_name
    'legislation_process'
  end

  def set_legislation_process_votes(processes) end


  def index_customization
    if process_type == "1"
      @resources = @resources.where('process_type in (?)', process_type)
    else
      @resources = @resources.visibles.where('process_type in (?)', process_type)
    end

    if process_type.length == 2 && process_type[0] == 2 && process_type[1] == 4
      @resources_map = @resources
    end

  end

  def large_map
    @processes = resource_model.all.by_user_pon.process_type(process_type)
  end

  #aggiunta una before_action per settare breadcrumb per le show di works, chances e processes_proposals
  def set_breadcrumb
    if @process.process_type === 2 || @process.process_type === 4
      add_breadcrumb t('breadcrumbs.services.works'), works_path
    elsif @process.process_type === 3 || @process.process_type === 5
      add_breadcrumb t('breadcrumbs.services.chances'), chances_path
    else
      add_breadcrumb t('breadcrumbs.services.processes_proposals'), processes_proposals_path
    end
  end

  def show
    load_data
    if @process.process_type === 4
      redirect_to sgap_legislation_process_path(@process)
      return
    end
    draft_version = @process.draft_versions.published.last
    if @process.allegations_phase.enabled? && @process.allegations_phase.started? && draft_version.present?
      redirect_to legislation_process_draft_version_path(@process, draft_version)
    elsif @process.debate_phase.enabled?
      redirect_to debate_legislation_process_path(@process)
    elsif @process.proposals_phase.enabled?
      redirect_to proposals_legislation_process_path(@process)
    else
      redirect_to details_legislation_process_path(@process)
    end
    set_breadcrumb
  end

  def debate
    load_data
    @phase = :debate_phase
    if @process.debate_phase #.started?
      render :debate
    else
      render :phase_not_open
    end
  end

  def social_flag
    @process = Legislation::Process.find_by(id: params[:id])
    @process.social_content.social_access = !@process.social_content.social_access
    @process.social_content.save
    @process.touch
    redirect_to :back, notice: t('notice.operaction_successfull')
  end

  def draft_publication
    load_data
    @phase = :draft_publication

    if @process.draft_publication.started?
      draft_version = @process.draft_versions.published.last

      if draft_version.present?
        redirect_to legislation_process_draft_version_path(@process, draft_version)
      else
        render :phase_empty
      end
    else
      render :phase_not_open
    end
  end

  def details
    load_data
    @phase = :detail_phase

    render :phase_not_open
  end

  def allegations
    load_data
    @phase = :allegations_phase

    if @process.allegations_phase.started?
      draft_version = @process.draft_versions.published.last

      if draft_version.present?
        redirect_to legislation_process_draft_version_path(@process, draft_version)
      else
        render :phase_empty
      end
    else
      render :phase_not_open
    end
  end

  def result_publication
    load_data
    @phase = :result_publication

    if @process.result_publication.started?
      final_version = @process.final_draft_version

      if final_version.present?
        redirect_to legislation_process_draft_version_path(@process, final_version)
      else
        render :phase_empty
      end
    else
      render :phase_not_open
    end
  end

  def proposals
    if @process.process_type == 1
      redirect_to debate_legislation_process_path(@process)
    else
      load_data
      @phase = :proposals_phase

      if @process.proposals_phase.started?
        legislation_proposal_votes(@process.proposals)
        render :proposals
      else
        render :phase_not_open
      end
    end
  end

  def json_data
    process = ::Legislation::Process.find(params[:id])
    data = {
        process_id: process.id,
        title: process.title,
        url: legislation_process_path(process)
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end

  def moderation_flag
    #setta moderazione su tutti dibattiti legati al progetto
    @process.questions.each do |item|
      item.moderation_flag = !item.moderation_flag 
      item.save
    end

    #setta moderazione su tutte le proposte legate al progetto
    @process.proposals.each do |item|
      item.moderation_flag = !item.moderation_flag 
      item.save
    end

    redirect_to :back, notice: t('notice.operaction_successfull') 
  end

  private

  def member_method?
    params[:id].present?
  end

  def load_data
    #return if member_method?
    p_id = params[:id]

    if params[:process_id].present?
      if params[:process_id] != nil
        id = params[:process_id]
      end
    end

    @process = ::Legislation::Process.find(p_id)

    if !@process.load_entity?(current_user)
      raise CanCan::AccessDenied
    end

    if !(current_user and current_user.administrator?)
      check_service_flag(@process.service_flag_name)
    end
  end


end
