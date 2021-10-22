class CommentsController < ApplicationController
  include CustomUrlsHelper
  include FeatureFlags
  include FlagActions
  include Gamification
 

  gamification :Comment

  before_action :authenticate_user!, only: :create
  before_action :load_commentable, only: :create
  before_action :verify_resident_for_commentable!, only: :create
  before_action :verify_comments_open!, only: [:create, :vote]
  #before_action :build_comment, only: :create
  before_action :load_data, only: [:show]

  load_and_authorize_resource
  respond_to :html, :js

  def create
    @comment = Comment.new(comment_params.merge(author: current_user))
    check_for_special_comments


    if comment_params[:as_rappr_legale].to_i > 0 and comment_params[:sector_id].to_i > 0
      sector = Sector.find(comment_params[:sector_id].to_i)
      SectorContent.create(sectorable: @comment, sector: sector)
    end

    if current_user.administrator? || current_user.moderator? || @commentable.moderation_flag == nil || @commentable.moderation_flag == false
      @comment.moderation_entity = 1
    else
      @comment.moderation_entity = 2
    end

    if @comment.save
      if (@comment.commentable.try(:pon_id))
        @comment.pon_id = @comment.commentable.pon_id
      else
        @comment.pon_id = User.pon_id
      end
      @comment.save
      if current_user.administrator? || current_user.moderator? || @commentable.moderation_flag == nil || @commentable.moderation_flag == false
        # Per i commenti non admin/mod, la notifica sarà inviata dopo l'apporvazione del moderatore/amministratore
        CommentNotifier.new(comment: @comment).process
        add_notification @comment

      else
        comments_c = @commentable.comments_count
        load_commentable
        @commentable.update_attribute(:comments_count, comments_c)
      end
      #gamification params
      self.action_service = @commentable.class.name
      if comment_params[:images_attributes].present? || comment_params[:documents_attributes].present?
        self.action_attribute = "attachment"
      end
      #####
    else
      render :new
    end
    #notice = t("admin.newsletters.create_success")
    #flash.now[:alert] = (alert || t("officing.results.flash.error_create")
    #logger.debug "-----redirect_to--------- "
  end

  def show
    @comment = Comment.find(params[:id])
    if @comment.valuation && @comment.author != current_user
      raise ActiveRecord::RecordNotFound
    else
      set_comment_flags(@comment.subtree)
    end
  end

  def vote
    #gamification params
    if @comment.user != current_user
      if params[:value] == 'yes'
        insert_user_action(@comment.commentable.class.name, @comment.user, "like")
      else
        insert_user_action(@comment.commentable.class.name, @comment.user, "unlike")
      end
    end
    #####
    @comment.vote_by(voter: current_user, vote: params[:value])
    respond_with @comment
  end

  def flag
    self.action_service = @comment.commentable.class.name
    Flag.flag(current_user, @comment)
    set_comment_flags(@comment)
    respond_with @comment, template: 'comments/_refresh_flag_actions'
  end

  def unflag
    self.action_service = @commentable.class.name
    Flag.unflag(current_user, @comment)
    set_comment_flags(@comment)
    respond_with @comment, template: 'comments/_refresh_flag_actions'
  end

  private

  def comment_params
    params.require(:comment).permit(:commentable_type, :commentable_id, :external_url, :parent_id,
                                    :body, :as_moderator, :as_administrator, :valuation,
                                    :as_rappr_legale, :sector_id,
                                    documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                    images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                    sector_content_attributes: [:sector_id])
      .merge(ignored_flag_at: nil)
  end

  def build_comment
    @comment = Comment.build(@commentable, current_user, comment_params[:body],
                             comment_params[:parent_id].presence,
                             comment_params[:valuation])
    check_for_special_comments
  end

  def check_for_special_comments
    if administrator_comment?
      @comment.administrator_id = current_user.administrator.id
    elsif moderator_comment?
      @comment.moderator_id = current_user.moderator.id
    end
  end

  def load_commentable
    @commentable = Comment.find_commentable(comment_params[:commentable_type],
                                            comment_params[:commentable_id])
  end

  def administrator_comment?
    ["1", true].include?(comment_params[:as_administrator]) &&
      can?(:comment_as_administrator, @commentable)
  end

  def moderator_comment?
    ["1", true].include?(comment_params[:as_moderator]) &&
      can?(:comment_as_moderator, @commentable)
  end

  def add_notification(comment)
    notifiable = comment.reply? ? comment.parent : comment.commentable
    notifiable_author_id = notifiable.try(:author_id)
    if notifiable_author_id.present? && notifiable_author_id != comment.author_id
      Notification.add(notifiable.author, notifiable)
    end
  end

  def verify_resident_for_commentable!
    return if current_user.administrator? || current_user.moderator?

    if @commentable.respond_to?(:comments_for_verified_residents_only?) &&
      @commentable.comments_for_verified_residents_only?
      verify_resident!
    end
  end

  def verify_comments_open!
    return if current_user.administrator? || current_user.moderator?

    if @commentable.respond_to?(:comments_closed?) && @commentable.comments_closed?
      redirect_to @commentable, alert: t('comments.comments_closed')
    end
  end

  def load_data
    @comment = Comment.find(params[:id])
    if !@comment.load_entity?(current_user) && cannot?(:retire, @comment)
      raise CanCan::AccessDenied
    end
  end

end
