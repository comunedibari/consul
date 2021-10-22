class EventSlot < ActiveRecord::Base
  
    belongs_to :event, class_name: 'Event', foreign_key: 'event_id'
    
    validates :start_event, presence: true
    validates :end_event, presence: true
    #validate :valid_date_ranges

    scope :by_event_date,     ->(event_date)     { where('start_event < ?', event_date).where('end_event > ?',event_date) }
    scope :by_filter_date,   ->(start_event) { where.any_of(by_event_date(start_event[1]),by_event_date(start_event[2]) ,start_event: start_event[0], end_event: start_event[0]).uniq.pluck(:event_id) }
    
    after_save :update_date_event
    
    def update_date_event
        event=Event.with_hidden.where(id: self.event_id).first
        if event
            if !event.start_event or event.start_event > self.start_event 
                event.start_event=self.start_event
            end
            if !event.end_event or event.end_event < self.end_event
                event.end_event=self.end_event
            end
            event.save
        else
            logger.error "-------------event not saved"
        end
    end

end
