class Admin::Collaboration::AgreementsController < Admin::Collaboration::BaseController
  include CommentableActions
  include Eventify
  
  has_filters %w{opens next past all}, only: :index
  before_action :destroy_map_location_association, only: :update
  

  before_action :load_agreement, only: [ :update, :show, :debate, :proposal, :result_publication, :allegations, :draft_publication]
  before_action :load_categories, only: [:index, :new, :create, :edit]
  load_and_authorize_resource class: "Collaboration::Agreement"


  include Gamification
 
  gamification "Collaboration::Agreement"

  def edit
    super
    @agreement.sector_id =  @agreement.sector_content.present? ? @agreement.sector_content.sector.id : nil
  end

  def new
    #@process = Legislation::Process.new
  end

  def index
    #mi prendo tutti i process dalla tabella processes che hanno process_type=1
    @agreements = ::Collaboration::Agreement.send(@current_filter).by_user_pon.where("agreement_type = 1").order('id DESC').page(params[:page])
  end

  def show
    render :edit
  end


  def create
    @agreement = ::Collaboration::Agreement.new(agreement_params.merge(author: current_user, agreement_type: 1, pon_id: current_user.pon_id))
    #al momento in cui faccio "nuovo progetto" sto nella "new" ..quindi compilo tutti i campi..
    #e quindi al momento del salvataggio sto nella "create" se il salvataggio su db è andato a buon fine
    @agreement.subscriptions_count = 0
    if @agreement.save

      if agreement_params[:sector_id].present? && agreement_params[:sector_id].to_i > 0
        sector = Sector.find(agreement_params[:sector_id].to_i)
        SectorContent.create(sectorable: @agreement, sector: sector )
      end

      #ti riporta alla pagina http://localhost:3000/legislation/processes
      link = collaboration_agreement_path(@agreement).html_safe
      notice = t('admin.collaboration.agreements.create.notice', link: link)
      #mi reindirizza alla pagina http://localhost:3000/admin/legislation/processes/24/edit
      create_as_event(@agreement)

      social_service = Setting.find_by(key: 'service_social.collaboration',pon_id: User.pon_id).value 
      SocialContent.create(sociable: @agreement, social_access:  social_service)


      redirect_to edit_admin_collaboration_agreement_path(@agreement), notice: notice
    else
      flash.now[:error] = t('admin.collaboration.agreements.create.error')
      #se non va bene con il "render" vado quà http://localhost:3000/admin/legislation/processes
      render :new
    end
  end

  


  
  def update
    super
    #se l'aggiornamento dei parametri del process è andato a buon fine
    if @agreement.sector_content.present?
      @agreement.sector_content.destroy
    end
    if agreement_params[:sector_id].present? and agreement_params[:sector_id].to_i > 0
      sector = Sector.find(agreement_params[:sector_id].to_i)
      SectorContent.create(sectorable: @agreement, sector: sector )
    end
    set_tag_list
    set_in_moderation
    if current_user.administrator? || current_user.moderator?
      link = collaboration_agreement_path(@agreement).html_safe
      update_event(@agreement)
      #redirect_to :back, notice: t('admin.collaboration.agreements.update.notice', link: link)
    end
  end 

  

  def destroy
    @agreement = ::Collaboration::Agreement.find(params[:id])
    destroy_event(@agreement)
    @agreement.destroy
    notice = t('admin.collaboration.agreements.destroy.notice')
    redirect_to admin_collaboration_agreements_path, notice: notice
  end

  def load_agreement
    @agreement = ::Collaboration::Agreement.by_user_pon.agreement_all_type.with_hidden.find(params[:id])
  end

  private

    def resource_model
      Collaboration::Agreement
    end

    def resource_name
      "agreement" #resource_model.parameterize('_')
    end

    def agreement_params

      if current_user.administrator? || current_user.moderator?
        moderation_entity_v = 1 
      else
        moderation_entity_v = 2
      end

      params.require(:collaboration_agreement).permit(
        :title,
        :summary,
        :description,
        :additional_info,
        :asset_description,
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
        :geozone_id,
        :sector_id,
        sector_content_attributes: [:sector_id],
        documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        map_location_attributes: [:latitude, :longitude, :zoom]
      )      
      .merge(moderation_entity: moderation_entity_v) 
    end

    def set_tag_list
      @agreement.set_tag_list_on(:customs, agreement_params[:custom_list])
      @agreement.save
    end



    def destroy_map_location_association
      map_location = params[:collaboration_agreement][:map_location_attributes]
      if map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?
        MapLocation.destroy(map_location[:id])
      end
    end

    def destroy_sector_content_association
      sector_content = params[:collaboration_agreement][:sector_content_attributes]
      if sector_content && (sector_content[:sector_id] && !sector_content[:id].blank?
        SectorContent.destroy(sector_content[:id]))
      end
    end
end
