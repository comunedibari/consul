module Gamification
  extend ActiveSupport::Concern 


  def insert_user_action(service, user, attribute)
    logger.debug "----------------------------------"
    logger.debug service.to_s
    logger.debug user.to_s
    logger.debug attribute.to_s
    logger.debug "----------------------------------"
    UserAction.insert(user, service, controller_name, action_name, attribute)
  end
  
  included do

    class_attribute :action_service
    class_attribute :action_attribute
    class_attribute :action_user


  end

  module ClassMethods

    private

    def gamification(name)

      self.action_service = name
      self.action_attribute = "0"

      after_action :except => [:index,:show,:large_map] do

        if self.action_attribute != "no_action"
          if current_user
            self.insert_user_action(self.action_service, current_user, self.action_attribute)
          end
        end
      end

    end

  end
end
