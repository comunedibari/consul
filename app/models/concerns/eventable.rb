module Eventable
    extend ActiveSupport::Concern
    #attr_accessor  :event_id

  
    included do
        has_one :event_content, as: :eventable, class_name: 'EventContent' #, dependent: :destroy
    end

    module ClassMethods

        private
        def eventable(options = {})
        end    
    end
  
end
  