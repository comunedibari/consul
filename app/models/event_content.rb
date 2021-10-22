class EventContent < ActiveRecord::Base

    include Eventable

    belongs_to :eventable, polymorphic: true
    belongs_to :event, class_name: 'Event', foreign_key: 'event_id'

end
