class Admin::Legislation::ProcessProcessesProposalsController < Admin::Legislation::ProcessesController
  include ServiceFlags
  #include Eventify

  service_flag :processes

  #disabilte questa before action per permettere la creazione indipendentemente dal PON di appartenenza
  #before_action :verify_permission

  #load_and_authorize_resource :class => "Legislation::Process" # IMPORTANTE (Quando il Nome model non coincide con il nome controller)
  load_and_authorize_resource :new, :class => "Legislation::Process"
  load_and_authorize_resource :create, :class => "Legislation::Process"
  #load_and_authorize_resource :social_flag ,:class => "Legislation::ProcessProcessesProposals"

  def new
    @process = ::Legislation::Process.new
    @process.author = current_user

  end

  def index
    @processes = ::Legislation::Process.send(@current_filter).by_user_pon.process_standard.order('id DESC')
    if !current_user.administrator?
      @processes = @processes.by_user(current_user)
    end
    @processes = @processes.page(params[:page])
  end

  def destroy
    @process = ::Legislation::Process.find(params[:id])
    #destroy_event(@process)
    @process.destroy
    notice = t('admin.legislation.processes.destroy.notice')
    redirect_to admin_legislation_process_processes_proposals_path, notice: notice
  end

  def create
    # fase di dibattito sempre aperta, progetto sempre visibile

    #@process = Legislation::Process.new(process_params.merge(author: current_user, process_type: 1, pon_id: current_user.pon_id, debate_start_date: "2019-01-01", debate_end_date: "9999-01-01", debate_phase_enabled: true,visible: true))
    @process = Legislation::Process.new(process_params.merge(author: current_user, process_type: 1, pon_id: session[:pon_id], debate_start_date: "2019-01-01", debate_end_date: "9999-01-01", debate_phase_enabled: true, published: true, visible: true))
    if @process.save

      #per creare il sectorable
      if process_params[:sector_id].present? && process_params[:sector_id].to_i > 0
        sector = Sector.find(process_params[:sector_id].to_i)
        SectorContent.create(sectorable: @process, sector: sector)
      end
      #create_as_event(@process)
      if current_user.administrator? || current_user.moderator?
        link = legislation_process_path(@process).html_safe
        notice = t('admin.legislation.processes.create.notice_admin', link: link)
        redirect_to link, notice: notice
      else
        link = user_path(current_user)
        notice = t('admin.legislation.processes.create.notice', link: link)
        redirect_to link, notice: notice
      end


      if current_user.administrator?
        if params[:legislation_process][:social_content][:social_access].to_i > 0
          SocialContent.create(sociable: @process, social_access: true)
        else
          SocialContent.create(sociable: @process, social_access: false)
        end
      else
        SocialContent.create(sociable: @process, social_access: false)
      end

      #crea una consultazione iniziale aperta
      @question = ::Legislation::Question.new(legislation_process_id: @process.id,
                                              title: "Discussione iniziale",
                                              author_id: @process.author_id
      )
      @question.save

    else
      flash.now[:error] = t('admin.legislation.processes.create.error')
      render :new
    end
  end

  def update
    @process = ::Legislation::Process.with_hidden.find(params[:id])
    load_categories
    #manage sector content
    if @process.sector_content.present?
      @process.sector_content.destroy
    end
    if process_params[:sector_id].present? && process_params[:sector_id].to_i > 0
      sector = Sector.find(process_params[:sector_id].to_i)
      SectorContent.create(sectorable: @process, sector: sector)
    end

    if @process.update(process_params)
      set_tag_list
      #update_event(@process)
      if current_user.administrator? || current_user.moderator?
        link = edit_admin_legislation_process_processes_proposal_path(@process).html_safe
        notice = t('admin.legislation.processes.update.notice_admin', link: link)
        redirect_to link, notice: notice
      else
        link = edit_admin_legislation_process_processes_proposal_path(@process).html_safe
        notice = t('admin.legislation.processes.update.notice', link: link)
        redirect_to link, notice: notice
      end


      #--------------------------------------
      if current_user.provider == "openam" || current_user.administrator?
        if params[:legislation_process][:social_content][:social_access].present?
          @social_content = SocialContent.where(sociable_type: 'Legislation::Process').where(sociable_id: @process.id).first

          if params[:legislation_process][:social_content][:social_access].to_i > 0
            @social_content.update_attribute(:social_access, true)
          else
            @social_content.update_attribute(:social_access, false)
          end
        end
      end


    else
      flash.now[:error] = t('admin.legislation.processes.update.error')
      render :edit
    end
  end

  private

  def verify_permission
    if current_user.pon_id != User.pon_id
      raise CanCan::AccessDenied
    end
  end

  def load_process
    if current_user.administrator? || current_user.moderator?
      @process = ::Legislation::Process.process_standard.by_user_pon.find(params[:id])
    else
      #@process = ::Legislation::Process.process_standard.by_user_pon.by_user(current_user).find(params[:id])
      @process = ::Legislation::Process.by_user_pon.process_standard.with_hidden.find(params[:id])
    end
  end

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
        #:debate_start_date,
        #:debate_end_date,
        :draft_publication_date,
        :allegations_start_date,
        :allegations_end_date,
        :proposals_phase_start_date,
        :proposals_phase_end_date,
        :result_publication_date,
        #:debate_phase_enabled,
        :allegations_phase_enabled,
        :proposals_phase_enabled,
        :draft_publication_enabled,
        :result_publication_enabled,
        #:published,
        :proposals_description,
        :custom_list,
        :skip_map,
        :geozone_id,
        :tag_list,
        :sector_id,
        :social_access,
        :legislation_process_typologies_id,
        sector_content_attributes: [:sector_id],
        documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        social_content_attributes: [:social_access],
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

end
