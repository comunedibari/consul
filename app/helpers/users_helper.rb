module UsersHelper

  def humanize_document_type(document_type)
    case document_type
    when "1"
      t "verification.residence.new.document_type.spanish_id"
    when "2"
      t "verification.residence.new.document_type.passport"
    when "3"
      t "verification.residence.new.document_type.residence_card"
    end
  end

  def comment_commentable_title(comment)
    commentable = comment.commentable
    if commentable.nil?
      deleted_commentable_text(comment)
    elsif commentable.hidden?
      content_tag(:del, commentable.title) + ' ' +
      content_tag(:span, '(' + deleted_commentable_text(comment) + ')', class: 'small')
    elsif !commentable.hidden? && comment.in_approval?
      commentable.title
    else
      link_to(commentable.title, comment_path(comment, pon_id: comment.pon_id))
    end
  end

  def deleted_commentable_text(comment)
    case comment.commentable_type
    when "Proposal"
      t("users.show.deleted_proposal")
    when "Crowdfunding"
      t("users.show.deleted_crowdfunding")
    when "Reporting"
      t("users.show.deleted_reporting")
    when "Debate"
      t("users.show.deleted_debate")
    when "Budget::Investment"
      t("users.show.deleted_budget_investment")
    when "Collaboration::Agreement"
      t("users.show.deleted_collaboration_agreement")
    else
      t("users.show.deleted")
    end
  end

  def current_administrator?
    current_user && current_user.administrator?
  end

  def current_moderator?
    current_user && current_user.moderator?
  end

  def current_valuator?
    current_user && current_user.valuator?
  end

  def current_manager?
    current_user && current_user.manager?
  end

  def show_admin_menu?
    current_administrator? || current_moderator? || current_valuator? || current_manager?
  end

  def show_moderation_menu?
    !current_administrator? && current_moderator?
  end

  def interests_title_text(user)
    if current_user == user
      t('account.show.public_interests_my_title_list')
    else
      t('account.show.public_interests_user_title_list')
    end
  end

  def go_to_login
    #if Rails.application.config.cm == 'cm1'
      #user_omniauth_authorize_path(:openam)
    #else
      new_user_session_path
    #end
  end

  def go_to_new_user
    #if Rails.application.config.cm == 'cm1'
      #user_omniauth_authorize_path(:openam)
    #else
      new_user_registration_path
    #end
  end

  def ctrl_service_active? filter
    has_service = {
      "proposals" => 'proposals',
      "processes" => 'processes',
      "crowdfundings" => 'crowdfundings',
      "works" => 'works',
      "chances" => 'chances',
      "reportings" => 'reportings',
      "debates" => 'debates',
      #"budget_investments" => 'budgets',
      "collaboration_agreements" => 'collaboration',
      #"comments" => 'comments',
      #"follows" => 'follows', #no
      "events" => 'events',
      "moderable_bookings" => 'assets'
    }

    if filter == 'works' or filter == 'chances'
      if (has_service['works'].nil? or  service?(has_service['works'])) or has_service['chances'].nil? or  service?(has_service['chances'])
        true
      else
        false
      end
    elsif has_service[filter].nil? or  service?(has_service[filter])
      true
    else
      false
    end
  end
end
