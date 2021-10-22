module Eventify
  extend ActiveSupport::Concern



 
  def create_as_event(resource)          
     
    author = User.system
    event = Event.new(author: author,
      title: resource.title,
      description: resource.description,
      skip_map: "1",
      all_day_event: TRUE,
      pon: resource.author.pon,
    )

    

    if !(current_user.administrator? && current_user.moderator?)
      event.hidden_at = Time.current
    end
    event_content = EventContent.new(eventable: resource, event: event )


    if resource.class.name.parameterize('_') == "poll"
      event.event_type = EventType.find(11)
    elsif resource.class.name.parameterize('_') == "crowdfunding"
      event.event_type = EventType.find(12)
      event.hidden_at = Time.current
    elsif resource.class.name.parameterize('_') == "legislation_processwork"
      event.event_type = EventType.find(13)
      event_content.eventable = resource.process
    elsif resource.class.name.parameterize('_') == "legislation_processchance"
      event.event_type = EventType.find(14)
      event_content.eventable = resource.process
    elsif resource.class.name.parameterize('_') == "collaboration_agreement"
      event.event_type = EventType.find(15)
    end

    event.save()
    event_content.save()

    EventSlot.create!(
      event: event,
      start_event:  resource.start_date,
      end_event:  resource.end_date,                                                                    
    ) 

    social_content = SocialContent.where(sociable_id: resource.id).where(sociable_type: resource.model_name.name).first
    if social_content
      if resource.social_content.social_access
        SocialContent.create(sociable: event, social_access: true)
      else
        SocialContent.create(sociable: event, social_access: false)
      end
    end

    event
  end


  def destroy_event(resource)

    if resource.event_content && resource.event_content.event.present? 
      event = resource.event_content.event
      event.destroy
    end  

  end




  def update_event(resource)
    if resource.event_content.present?
      event = Event.with_hidden.where(id: resource.event_content.event_id).first
      if !(current_user.administrator? && current_user.moderator?)
        event.hidden_at = Time.current
      end

      if event.present? && !event.nil?
        event.title = resource.title
        event.description = resource.description
        event.start_event = resource.start_date
        event.end_event = resource.end_date
        event.save
      end
      slot = event.event_slots[0]
      slot.start_event=resource.start_date
      slot.end_event=resource.end_date
      slot.save

    end    
    event
  end



end
