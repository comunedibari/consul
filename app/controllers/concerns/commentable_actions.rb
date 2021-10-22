module CommentableActions
  extend ActiveSupport::Concern
  include Polymorphic
  include Search

  def index
    #mod_approved da includere
    if resource_model.column_names.include? 'pon_id'
      @resources = resource_model.mod_approved.by_user_pon
    else
      @resources = resource_model.mod_approved
    end

    @resources = @current_order == "recommendations" && current_user.present? ? @resources.recommendations(current_user) : @resources.for_render

    @resources = @resources.search(@search_terms) if @search_terms.present?
    index_customization if index_customization.present?
    @tot_resources = @resources.count

    @resources = @resources.send(@current_filter) unless @current_filter == nil
    @resources = @advanced_search_terms.present? ? @resources.filter(@advanced_search_terms) : @resources
    @resources = @typology_ids_array.present? ? @resources.filter_by_typology(@typology_ids_array) : @resources
    @resources = @resources.tagged_with(@tag_filter) if @tag_filter

    @resources = @resources.page(params[:page]).send("sort_by_#{@current_order}")

    @tag_cloud = tag_cloud
    @banners = Banner.by_user_pon.with_active

    set_resource_votes(@resources)

    set_resources_instance

    load_data_extended if load_data_extended.present?
  end

  def show
    set_resource_votes(resource)
    @commentable = resource
    @comment_tree = CommentTree.new(@commentable, params[:page], @current_order)
    set_comment_flags(@comment_tree.comments)
    set_resource_instance
  end

  def new
    @resource = resource_model.new
    set_geozone
    set_resource_instance
  end

  def suggest
    @limit = 5
    @resources = @search_terms.present? ? resource_relation.search(@search_terms) : nil
  end

  def create
    @resource = resource_model.new(strong_params)
    @resource.author = current_user

    if @resource.save
      track_event
      redirect_path = url_for(controller: controller_name, action: :show, id: @resource.id)
      redirect_to redirect_path, notice: t("flash.actions.create.#{resource_name.underscore}")
    else
      load_categories
      load_geozones
      set_resource_instance
      render :new
    end
  end

  def edit
  end

  def update
    # Aggiornamento fallito, renderizziamo l'edit
    unless resource.update(strong_params)
      load_categories
      load_geozones
      set_resource_instance
      render :edit
      nil
    end

    # Aggiornamento riuscito, eseguiamo dei controlli:



    # Switch per risorse particolari che hanno bisogno di redirect specifici
    case controller_path
    when "legislation/proposals"
      redirect_to legislation_process_proposal_path(resource.legislation_process_id, resource), notice: I18n.t("flash.actions.update.#{resource_name.underscore}")
      return
    when "collaboration/agreements"
      redirect_to collaboration_agreement_path(resource.collaboration_agreement_id, resource), notice: I18n.t("flash.actions.update.#{resource_name.underscore}")
      return
    when "admin/crowdfundings"
      redirect_to toedit_admin_crowdfunding_path(resource.id, resource), notice: I18n.t("flash.actions.update.#{resource_name.underscore}")
      return
    end

    # Update delle risorse standard
    if ['debate', 'proposal', 'event', 'reporting', 'comment', 'process', 'agreement'].include?(resource_name)
      if current_user.administrator? || current_user.moderator?
        redirect_to resource, notice: I18n.t("flash.actions.update.#{resource_name.underscore}")
        return
      else
        redirect_to user_path(current_user), notice: I18n.t("flash.actions.update.#{resource_name.underscore}_in_approval")
        return
      end
    end

    # Tutte le altre casistiche
    redirect_to resource, notice: t("flash.actions.update.#{resource_name.underscore}")



  end

  def map
    @resource = resource_model.new
    @tag_cloud = tag_cloud
  end

  private

  def track_event
    ahoy.track "#{resource_name}_created".to_sym, "#{resource_name}_id": resource.id
  end

  def tag_cloud
    TagCloud.new(resource_model, params[:search])
  end

  def load_geozones
    @geozones = Geozone.by_user_pon.order(name: :asc)
  end

  def set_geozone
    geozone_id = params[resource_name.to_sym].try(:[], :geozone_id)
    @resource.geozone = Geozone.by_user_pon.find(geozone_id) if geozone_id.present?
  end

  def load_categories
    # load only user preferences
    @categories = ActsAsTaggableOn::Tag.category.order(:name)
  end

  def parse_tag_filter
    if params[:tag].present?
      @tag_filter = params[:tag] if ActsAsTaggableOn::Tag.named(params[:tag]).exists?
    end
  end

  def set_resource_votes(instance)
    if resource_name == "legislation_proposal"
      send("#{resource_name}_votes", instance)
    else
      send("set_#{resource_name}_votes", instance)
    end
  end

  def index_customization
    nil
  end

  def load_data_extended
    nil
  end

end
