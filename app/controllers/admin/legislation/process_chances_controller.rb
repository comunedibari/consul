class Admin::Legislation::ProcessChancesController < Admin::Legislation::ProcessesController
  include ServiceFlags
  include Eventify

  service_flag :chances
  
  def verify_administrator
    if params[:id]
      id = params[:id].split("-")[0].to_i
      p_type = ::Legislation::Process.where(id: id).first.process_type
      raise CanCan::AccessDenied if !current_user.try(:administrator?) #|| p_type == 5
    else
      raise CanCan::AccessDenied unless current_user.try(:administrator?)
    end
  end

  def new
    @process = ::Legislation::Process.new
    @process.process_chance = ::Legislation::ProcessChance.new
  end

  def index
    @processes = ::Legislation::Process.send(@current_filter).by_user_pon.process_chance_edit.order('id DESC').page(params[:page])
  end

  def destroy
    @process = ::Legislation::Process.find(params[:id])
    destroy_event(@process)
    @process.proposals
    @process.destroy
    notice = t('admin.legislation.processes.destroy.notice')
    redirect_to admin_legislation_process_chances_path, notice: notice
  end

  def create
    # fase di dibattito sempre apert
    #.merge(debate_start_date: "2019-01-01", debate_end_date: "9999-01-01", debate_phase_enabled: True)

    @process = ::Legislation::Process.new(process_params.merge(author: current_user,pon_id: current_user.pon_id, debate_start_date: "2019-01-01", debate_end_date: "9999-01-01", debate_phase_enabled: true))
    
    if !@process.process_type
      @process.process_type = 3
    end

    if @process.save
      

      #per creare il sectorable
  
      if process_params[:as_rappr_legale].to_i > 0 and process_params[:sector_id].to_i > 0
        sector = Sector.find(process_params[:sector_id].to_i)
        SectorContent.create(sectorable: @process, sector: sector )
      end
       #per creare il chence anche se è un entità vuota
      if !@process.process_chance.present?
        @process.process_chance = ::Legislation::ProcessChance.new
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
      
      link = admin_legislation_process_chance_path(@process).html_safe
      notice = t('admin.legislation.process_chance.update.notice_admin', link: link)
      create_as_event(@process.process_chance)
      redirect_to edit_admin_legislation_process_chance_path(@process), notice: notice
    else
      flash.now[:error] = t('admin.legislation.processes.create.error')
      render :new
    end
  end




  def update
    @process = ::Legislation::Process.find(params[:id])
    load_categories
    #manage sector content
    if @process.sector_content.present?
      @process.sector_content.destroy
    end

    if @process.update(process_params)
      if process_params[:sector_id].present? && process_params[:sector_id].to_i > 0
        sector = Sector.find(process_params[:sector_id].to_i)
        SectorContent.create(sectorable: @process, sector: sector )
      end
      set_tag_list
      link = edit_admin_legislation_process_chance_path(@process).html_safe
      notice = t('admin.legislation.process_chance.update.notice_admin', link: link)
      update_event(@process)


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


      redirect_to link, notice: notice
    else
      flash.now[:error] = t('admin.legislation.processes.update.error')
      render :edit
    end
  end



  def load_process
    @process = ::Legislation::Process.process_chance.by_user_pon.process_chance().find(params[:id])
  end

  private
      
    def process_params

      if @process
        if @process.process_type == 3 
          process_type_v = 3 
        elsif @process.process_type == 5
          process_type_v = 5
        end
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
        :published,
        :proposals_description,
        :custom_list,
        :skip_map,
        :geozone_id,
        :sector_id,
        :tag_list,
        :visible,
        :social_access,
        social_content_attributes: [:social_access],
        sector_content_attributes: [:sector_id],
        documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        map_location_attributes: [:latitude, :longitude, :zoom],
        process_chance_attributes: [:id, :legislation_process_id,:contacts,:address ,:benefit, :addressed_to, :purpose, :progress_status, :info]
      )
      .merge(process_type: process_type_v)
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
