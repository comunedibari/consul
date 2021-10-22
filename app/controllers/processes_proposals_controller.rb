class ProcessesProposalsController < Legislation::ProcessesController
  include ServiceFlags
  service_flag :processes

  has_filters %w{opens next past}, only: [:index, :filter_by_typology]
  before_action :load_categories, only: [:index, :filter_by_typology]

  before_action :load_process_typologies

  #add proposte e progetti breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.processes_proposals").html_safe, :processes_proposals_path


  def process_type
    [1]
  end

  def load_process_typologies
    @typologies = ::Legislation::ProcessTypology.all.order(id: :asc)
  end

  def filter_by_typology
    # Se non dovessero arrivare i parametri di ricerca, reindirizziamo alla index
    unless params[:typology].present?
      redirect_to processes_proposals_path
      return
    end

    typology_id = params[:typology][:id]
    filter_param = params[:filter].to_sym

    typology_id_array = typology_id.split(",")

    if typology_id_array.count > 0
      @resources = Legislation::Process.send(filter_param)
                       .by_user_pon
                       .process_type(1)
                       .published
                       .filter_by_typology(typology_id_array)
                       .order('id DESC')
                       .page(params[:page])
    else
      @resources = Legislation::Process.send(filter_param)
                       .by_user_pon
                       .process_type(1)
                       .published
                       .order('id DESC')
                       .page(params[:page])
    end
    render :index
  end

  def load_categories
    # load only user preferences
    @categories = ActsAsTaggableOn::Tag.category.order(:name)
  end

end
