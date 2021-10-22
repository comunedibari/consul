module EventsHelper
  
  def event_current_editable?(event)
    if event.event_type.creable < 1
     current_user && event.editable_by?(current_user)
    else
      false
    end
  end

  def empty_recommended_events_message_text(user)
    if user.interests.any?
      t('events.index.recommendations.without_results')
    else
      t('events.index.recommendations.without_interests')
    end
  end

  def has_featured?
    Event.all.featured.count > 0
  end

  def event_current_moderable_comments?(event)
    current_user && event.moderable_comments_by?(current_user)
  end
  
  def author_of_event?(event)
    author_of?(event, current_user)
  end

  
  def events_default_view?
    @view == "default"
  end

  def events_minimal_view_path
    events_path(view: events_secondary_view)
  end


  def events_current_view
    @view
  end

  def events_secondary_view
    events_current_view == "default" ? "minimal" : "default"
  end

  def ceck_author(id)
    author = User.system
    id == author.id
  end
end
