class Legislation::ProposalsController < Legislation::BaseController
  include CommentableActions
  include FlagActions

  load_and_authorize_resource :process
  load_and_authorize_resource :proposal, through: :process

  before_action :parse_tag_filter, only: :index
  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary]
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :authenticate_user!, except: [:index, :show, :map, :summary]
  before_action :load_data, only: [ :edit, :update, :show]

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders %w{confidence_score created_at}, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  helper_method :resource_model, :resource_name
  respond_to :html, :js

  def load_data 
    @proposal = ::Legislation::Proposal.find(params[:id])
    @legislation_proposal = @proposal
    if !@proposal.load_entity?(current_user)
      raise CanCan::AccessDenied
    end 
  end  

  def flag
    Flag.flag(current_user, @proposal)
    respond_with @proposal, 
    :location => legislation_process_proposal_path(@proposal.process.id, @proposal),
    template: 'legilsation/proposals/_refresh_flag_actions'
  end

  def unflag
    Flag.unflag(current_user, @proposal)
    respond_with @proposal, 
    :location => legislation_process_proposal_path(@proposal.process.id, @proposal),
     template: 'legilsation/proposals/_refresh_flag_actions'
  end

  def show
    super
    legislation_proposal_votes(@process.proposals)
    @document = Document.new(documentable: @proposal)
    if request.path != legislation_process_proposal_path(params[:process_id], @proposal)
      redirect_to legislation_process_proposal_path(params[:process_id], @proposal),
                  status: :moved_permanently
    end
  end

  def create
    @proposal = ::Legislation::Proposal.new(proposal_params.merge(author: current_user))

    if @proposal.save
      if proposal_params[:sector_id].present? and proposal_params[:sector_id].to_i > 0
        sector = Sector.find(proposal_params[:sector_id].to_i)
        #SectorContent.create(sectorable: @proposal, sector_id:  Sector.find(proposal_params[:sector_id].to_i))
        SectorContent.create(sectorable: @proposal, sector: sector)
      end



      if current_user.administrator?
        if params[:legislation_proposal][:social_content][:social_access].to_i > 0
          SocialContent.create(sociable: @proposal, social_access: true)
        else
          SocialContent.create(sociable: @proposal, social_access: false)
        end
      else
        @process = Legislation::Process.find(@proposal.legislation_process_id)
        if @process.process_type == 1
          social_service = Setting.find_by(key: 'service_social.legislation_process_processes_proposal',pon_id: User.pon_id).value 
          #SocialContent.create(sociable: @proposal, social_access: social_service)
          SocialContent.create(sociable: @proposal, social_access: true)
        else
          SocialContent.create(sociable: @proposal, social_access: false)
        end
      end 


      if current_user.administrator? || current_user.moderator?
        redirect_to legislation_process_proposal_path(params[:process_id], @proposal), notice: I18n.t('flash.actions.create.legislation_proposal')
      else
        redirect_to user_path(current_user), notice: I18n.t('flash.actions.create.legislation_proposal_in_approval')
      end      
    else
      render :new
    end
  end


  def retire
    if valid_retired_params? && @proposal.update(retired_params.merge(retired_at: Time.current))
      redirect_to legislation_process_proposal_path(@proposal.legislation_process_id, @proposal), notice: t('crowdfundings.notice.retired')
    else
      render action: :retire_form
    end
  end



  def retire_form

  end

  def  moderation_flag
    #Geastione del moderation flag centralizzata sul progetto da cui dipende
    #proposal = ::Legislation::Proposal.find_by(id: params[:id])
    #proposal.moderation_flag = !proposal.moderation_flag 
    #proposal.save
    #redirect_to :back, notice: t('notice.operaction_successfull') 
  end


  def index_customization
    load_retired
    load_successful_proposals
    load_featured unless @proposal_successful_exists
  end

  def vote
    @proposal.register_vote(current_user, params[:value])
    legislation_proposal_votes(@proposal)
  end

  private

    def proposal_params
      
      if current_user.administrator? || current_user.moderator?
        moderation_entity_v = 1 
      else
        moderation_entity_v = 2
      end  
      
      params.require(:legislation_proposal).permit(:legislation_process_id, :title,
                    :question, :summary, :description, :video_url, :tag_list,
                    :terms_of_service, :geozone_id,
                    :as_rappr_legale,:sector_id,:social_access,
                    sector_content_attributes: [:sector_id],
                    social_content_attributes: [:social_access],
                    documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id])
                    .merge(moderation_entity: moderation_entity_v)
    end

    def retired_params
      params.require(:legislation_proposal).permit(:retired_reason, :retired_explanation)
    end

    def valid_retired_params?
      @proposal.errors.add(:retired_reason, I18n.t('errors.messages.blank')) if params[:legislation_proposal][:retired_reason].blank?
      @proposal.errors.add(:retired_explanation, I18n.t('errors.messages.blank')) if params[:legislation_proposal][:retired_explanation].blank?
      @proposal.errors.empty?
    end    

    def load_retired
      if params[:retired].present?
        @resources = @resources.retired
        @resources = @resources.where(retired_reason: params[:retired]) if ::Legislation::Proposal::RETIRE_OPTIONS.include?(params[:retired])
      else
        @resources = @resources.not_retired
      end
    end    

    def resource_model
      Legislation::Proposal
    end

    def resource_name
      'legislation_proposal'
    end

    def load_successful_proposals
      @proposal_successful_exists = ::Legislation::Proposal.successful.exists?
    end

end
