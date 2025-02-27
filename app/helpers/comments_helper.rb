module CommentsHelper

  def comment_tree_title_text(commentable)
    if commentable.class == Legislation::Question
      t("legislation.questions.comments.comments_title")
    else
      t("comments_helper.comments_title")
    end
  end

  def leave_comment_text(commentable)
    if commentable.class == Legislation::Question
      t("legislation.questions.comments.form.leave_comment")
    else
      t("comments.form.leave_comment")
    end
  end

  def comment_link_text(parent_id)
    parent_id.present? ? t("comments_helper.reply_link") : t("comments_helper.comment_link")
  end

  def comment_button_text(parent_id, commentable)
    if commentable.class == Legislation::Question
      parent_id.present? ? t("comments_helper.reply_button") : t("legislation.questions.comments.comment_button")
    else
      parent_id.present? ? t("comments_helper.reply_button") : t("comments_helper.comment_button")
    end
  end

  def parent_or_commentable_dom_id(parent_id, commentable)
    parent_id.blank? ? dom_id(commentable) : "comment_#{parent_id}"
  end

  def child_comments_of(parent)
    if @comment_tree.present?
      @comment_tree.ordered_children_of(parent)
    else
      #parent.children
      comm_child = Array.new
      for i in 0..parent.children.size-1 do
        if parent.children[i].moderation_entity == 1 || parent.children[i].moderation_entity == nil
          comm_child.push(parent.children[i])
        end
      end
      comm_child
    end
  end

  

  def commentable_path(comment)
    commentable = comment.commentable

    case comment.commentable_type
    when "Budget::Investment"
      budget_investment_path(commentable.budget_id, commentable)
    when "Legislation::Question"
      legislation_process_question_path(commentable.process, commentable)
    when "Legislation::Annotation"
      legislation_process_draft_version_annotation_path(commentable.draft_version.process, commentable.draft_version, commentable)
    when "Topic"
      community_topic_path(commentable.community, commentable)
    when "Legislation::Proposal"
      legislation_process_proposal_path(commentable.legislation_process_id, commentable)
    else
      commentable
    end
  end

  def user_level_class(comment)
    if comment.as_administrator?
      "is-admin"
    elsif comment.as_moderator?
      "is-moderator"
    elsif comment.user.official?
      "level-#{comment.user.official_level}"
    else
      "" # Default no special user class
    end
  end

  def comment_author_class(comment, author_id)
    if comment.user_id == author_id
      "is-author"
    else
      "" # Default not author class
    end
  end

  def require_verified_resident_for_commentable?(commentable, current_user)
    return false if current_user.administrator? || current_user.moderator?

    commentable.respond_to?(:comments_for_verified_residents_only?) &&
      commentable.comments_for_verified_residents_only? &&
      !current_user.residence_verified?
  end

  def comments_closed_for_commentable?(commentable)
    commentable.respond_to?(:comments_closed?) && commentable.comments_closed?
  end

  def comments_closed_text(commentable)
    if commentable.class == Legislation::Question
      t("legislation.questions.comments.comments_closed")
    else
      t("comments.comments_closed")
    end
  end


  def child_comments_size(comment)
    dim=0
    for i in 0..comment.children.size-1 do
      if comment.children[i].moderation_entity == 1 || comment.children[i].moderation_entity == nil
        dim+=1
      end
    end
    dim
  end
  
  def can_user_sector_content? (user_c)
    Sector.where("user_id = ?", user_c.id).where(visible: true).count > 0
  end
  
end
