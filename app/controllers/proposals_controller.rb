class ProposalsController < ApplicationController
  include ServiceFlags
  include CommentableActions
  include FlagActions
  include NotificationsHelper

  include Gamification

  gamification :Proposal

  before_action :parse_tag_filter, only: :index
  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary]
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :authenticate_user!, except: [:index, :show, :map, :summary, :json_data, :large_map]
  before_action :destroy_map_location_association, only: :update
  before_action :set_view, only: :index
  before_action :load_data, only: [ :edit, :update, :show]

  skip_authorization_check only: :json_data

  service_flag :proposals



  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders ->(c) { Proposal.proposals_orders(c.current_user) }, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  load_and_authorize_resource
  helper_method :resource_model, :resource_name
  respond_to :html, :js

  #add petizioni breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.proposals") , :proposals_path

  def load_data
    @proposal = Proposal.find(params[:id])
    if !@proposal.load_entity?(current_user)
      raise CanCan::AccessDenied
    end
  end


  def large_map
    @proposals=@proposals.by_user_pon
  end


  def show
    super
    load_data
    @notifications = @proposal.notifications
    @related_contents = Kaminari.paginate_array(@proposal.relationed_contents).page(params[:page]).per(5)

    redirect_to proposal_path(@proposal), status: :moved_permanently if request.path != proposal_path(@proposal)
  end

  def edit
    super
    @proposal.sector_id =  @proposal.sector_content.present? ? @proposal.sector_content.sector.id : nil
  end

  def update
    super
    if @proposal.sector_content.present?
      @proposal.sector_content.destroy
    end
    if proposal_params[:sector_id].present? and proposal_params[:sector_id].to_i > 0
      sector = Sector.find(proposal_params[:sector_id].to_i)
      SectorContent.create(sectorable: @proposal, sector: sector )
    end
    #--------------------------------------
      if current_user.provider == "openam" || current_user.administrator?
        if params[:proposal][:social_content][:social_access].present?
          @social_content = SocialContent.where(sociable_type: 'Proposal').where(sociable_id: @proposal.id).first
          if params[:proposal][:social_content][:social_access].to_i > 0
            @social_content.update_attribute(:social_access, true)
          else
            @social_content.update_attribute(:social_access, false)
          end
        end
      end
  end


  def create
    #@proposal = Proposal.new(proposal_params.merge(author: current_user,pon_id: current_user.pon_id))
    @proposal = Proposal.new(proposal_params.merge(author: current_user,pon_id: session[:pon_id]))
    if @proposal.save
      #per creare il sectorable
      if proposal_params[:sector_id].present? and proposal_params[:sector_id].to_i > 0
        sector = Sector.find(proposal_params[:sector_id].to_i)
        SectorContent.create(sectorable: @proposal, sector: sector )
      end


      if current_user.administrator?
        if params[:proposal][:social_content][:social_access].to_i > 0
          SocialContent.create(sociable: @proposal, social_access: true)
        else
          SocialContent.create(sociable: @proposal, social_access: false)
        end
      else
        social_service = Setting.find_by(key: 'service_social.proposals',pon_id: User.pon_id).value
        SocialContent.create(sociable: @proposal, social_access: social_service)
      end



      #add geolocation to proposal if exists user coords
      if current_user.administrator? || current_user.moderator?
        redirect_to share_proposal_path(@proposal), notice: I18n.t('flash.actions.create.proposal')
        send_notification_tags(@proposal)
      else
        redirect_to user_path(current_user), notice: I18n.t('flash.actions.create.proposal_in_approval')
      end


    else
      render :new
    end
  end


  def  moderation_flag
    proposal = Proposal.find_by(id: params[:id])
    proposal.moderation_flag = !proposal.moderation_flag
    proposal.save
    redirect_to :back, notice: t('notice.operaction_successfull')
  end

  def social_flag
    @proposal = Proposal.find_by(id: params[:id])
    @proposal.social_content.social_access = !@proposal.social_content.social_access
    @proposal.social_content.save
    @proposal.touch

    redirect_to :back, notice: t('notice.operaction_successfull')
  end


  def index_customization
    discard_archived
    load_retired
    load_successful_proposals
    load_featured unless @proposal_successful_exists
  end

  def vote
    @proposal.register_vote(current_user, 'yes')
    set_proposal_votes(@proposal)

    insert_user_action(self.action_service, @proposal.author, "support")

  end

  def retire
    if valid_retired_params? && @proposal.update(retired_params.merge(retired_at: Time.current))
      redirect_to proposal_path(@proposal), notice: t('proposals.notice.retired')
    else
      render action: :retire_form
    end
  end

  def retire_form
  end

  def share
    if Setting['proposal_improvement_path',User.pon_id].present?
      @proposal_improvement_path = Setting['proposal_improvement_path',User.pon_id]
    end
  end

  def vote_featured
    @proposal.register_vote(current_user, 'yes')
    set_featured_proposal_votes(@proposal)
  end

  def summary
    @proposals = Proposal.by_user_pon.for_summary
    @tag_cloud = tag_cloud
  end

  def json_data
    proposal =  Proposal.find(params[:id])
    data = {
      proposal_id: proposal.id,
      title: proposal.title,
      author_id: proposal.author_id,
      url: proposal_path(proposal)
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end

  private

    def send_notification_tags(resource)
      send_notification_for_tags(resource)
    end

    def proposal_params
      if current_user.administrator? || current_user.moderator?
        moderation_entity_v=1
      else
        moderation_entity_v=2
      end
      params.require(:proposal).permit(:title, :question, :summary, :description, :external_url, :video_url,
                                      :responsible_name, :tag_list, :terms_of_service, :geozone_id, :skip_map,
                                      :as_rappr_legale,:sector_id,:social_access,
                                      documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      map_location_attributes: [:latitude, :longitude, :zoom],
                                      social_content_attributes: [:social_access],
                                      sector_content_attributes: [:sector_id]
                                      )#.merge(pon_id: User.pon_id)
                                      .merge(moderation_entity: moderation_entity_v)
    end

    def retired_params
      params.require(:proposal).permit(:retired_reason, :retired_explanation)
    end

    def valid_retired_params?
      @proposal.errors.add(:retired_reason, I18n.t('errors.messages.blank')) if params[:proposal][:retired_reason].blank?
      @proposal.errors.add(:retired_explanation, I18n.t('errors.messages.blank')) if params[:proposal][:retired_explanation].blank?
      @proposal.errors.empty?
    end

    def resource_model
      Proposal
    end

    def set_featured_proposal_votes(proposals)
      @featured_proposals_votes = current_user ? current_user.proposal_votes(proposals) : {}
    end

    def discard_archived
      @resources = @resources.not_archived unless @current_order == "archival_date"
    end

    def load_retired
      if params[:retired].present?
        @resources = @resources.retired
        @resources = @resources.where(retired_reason: params[:retired]) if Proposal::RETIRE_OPTIONS.include?(params[:retired])
      else
        @resources = @resources.not_retired
      end
    end

    def load_featured
      return unless !@advanced_search_terms && @search_terms.blank? && @tag_filter.blank? && params[:retired].blank? && @current_order != "recommendations"
      @featured_proposals = Proposal.where(moderation_entity: 1).by_user_pon.not_archived.sort_by_confidence_score.limit(3)
      if @featured_proposals.present?
        set_featured_proposal_votes(@featured_proposals)
        @resources = @resources.where('proposals.id NOT IN (?)', @featured_proposals.map(&:id))
      end
    end

    def set_view
      @view = (params[:view] == "minimal") ? "minimal" : "default"
    end

    def load_successful_proposals
      @proposal_successful_exists = Proposal.by_user_pon.successful.exists?
    end

    def destroy_map_location_association
      map_location = params[:proposal][:map_location_attributes]
      skip_map =params[:proposal][:skip_map]
      if skip_map == "1" || (map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?)
        MapLocation.destroy(map_location[:id])
      end
    end

end
