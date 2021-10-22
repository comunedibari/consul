class Collaboration::AgreementsController < ApplicationController  
  include ServiceFlags
  include CommentableActions
  include FlagActions

  service_flag :collaboration
  before_action :load_data, only: [ :edit, :update, :show, :debate, :proposal, :result_publication, :allegations, :draft_publication, :sgap]
  load_and_authorize_resource :collaboration_agreement, class: "Collaboration::Agreement"
  helper_method :resource_model, :resource_name
  respond_to :html, :js
  

  has_orders ->(c) { Collaboration::Agreement.agreements_orders(c.current_user) }, only: :index
  has_orders %w{most_voted newest oldest}, only: :show
  has_filters %w{opens past}, only: [:index, :oportunities ]


  skip_authorization_check only: [:json_data ]

  before_action :parse_tag_filter, only:  [:index, :oportunities ]

  before_action :authenticate_user!, except: [:index, :show, :map, :summary, :json_data, :large_map, :debate, :proposal, :result_publication, :allegations, :draft_publication, :sgap] 
 

  before_action :load_categories, only: [:index, :oportunities, :new, :create, :edit, :map, :summary]
  before_action :load_tag_cloud

  #add patto di collaborazione breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.collaboration_agreements"), :collaboration_agreements_path

  def load_tag_cloud
    @tag_cloud = tag_cloud
  end

  def resource_model
    Collaboration::Agreement
  end


  def resource_name
    "collaboration_agreement"
  end

  def agreement_type
    [1, 2, 3, 4]
  end


  def set_collaboration_agreement_votes(agreements)
  end


  def index_customization
    @resources = @resources.published.where('agreement_type in (?)',agreement_type)
    #@tot_resources = @resources.count
    #@resources = @resources.send(@current_filter) unless @current_filter == nil
    #@agreements = @resources
  end

  def show
    @notifications = @collaboration_agreement.notifications
    @commentable = @collaboration_agreement
    @comment_tree = CommentTree.new(@commentable, params[:page], @current_order)
    set_comment_flags(@comment_tree.comments)
   end


  
  def large_map
    @agreements = resource_model.all.by_user_pon.agreement_type(agreement_type)
  end

  def social_flag
    @collaboration_agreement = Collaboration::Agreement.find_by(id: params[:id])
    @collaboration_agreement.social_content.social_access = !@collaboration_agreement.social_content.social_access
    @collaboration_agreement.social_content.save
    @collaboration_agreement.touch

    redirect_to :back, notice: t('notice.operaction_successfull') 
  end


  def  moderation_flag
    agreement = Collaboration::Agreement.find_by(id: params[:id])
    agreement.moderation_flag = !agreement.moderation_flag 
    agreement.save
    redirect_to :back, notice: t('notice.operaction_successfull') 
  end


  def debate
    @phase = :debate_phase

    if @agreement.debate_phase.started?
      render :debate
    else
      render :phase_not_open
    end
  end

  def draft_publication
    # @phase = :draft_publication

    # if @agreement.draft_publication.started?
    #   draft_version = @agreement.draft_versions.published.last

    #   if draft_version.present?
    #     redirect_to legislation_process_draft_version_path(@process, draft_version)
    #   else
    #     render :phase_empty
    #   end
    # else
    #   render :phase_not_open
    # end
  end

  def allegations
     @phase = :allegations_phase
    
     if @agreement.allegations_phase.started?
       draft_version = @agreement.draft_versions.published.last

    #   if draft_version.present?
    #     redirect_to legislation_process_draft_version_path(@process, draft_version)
    #   else
    #     render :phase_empty
    #   end
    # else
    #   render :phase_not_open
     end
  end

  def result_publication
    # @phase = :result_publication

    # if @process.result_publication.started?
    #   final_version = @process.final_draft_version

    #   if final_version.present?
    #     redirect_to legislation_process_draft_version_path(@process, final_version)
    #   else
    #     render :phase_empty
    #   end
    # else
    #   render :phase_not_open
    # end
  end

  def proposals
    # @phase = :proposals_phase

    # if @process.proposals_phase.started?
    #   legislation_proposal_votes(@process.proposals)
    #   render :proposals
    # else
    #   render :phase_not_open
    # end
  end

  def json_data
    agreement =  ::Collaboration::Agreement.find(params[:id])
    data = {
      agreement_id: agreement.id,
      title: agreement.title,
      url: collaboration_agreement_path(agreement)
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end


  private

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
        :social_access,
        sector_content_attributes: [:sector_id],
        social_content_attributes: [:social_access],
        documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
        map_location_attributes: [:latitude, :longitude, :zoom]
      )      
      .merge(moderation_entity: moderation_entity_v) 
    end

    def member_method?
      params[:id].present?
    end

    def load_data
      #return if member_method?
      p_id = params[:id]

      if params[:agreement_id].present? 
        if params[:agreement_id] != nil
          id = params[:agreement_id]
        end
      end
      @collaboration_agreement = ::Collaboration::Agreement.find(p_id)
      if !@collaboration_agreement.load_entity?(current_user)
        raise CanCan::AccessDenied
      end
    end

    

end
