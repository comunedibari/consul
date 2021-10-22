class UserAction < ActiveRecord::Base
  belongs_to :user
  belongs_to :gamification_rule

  scope :unscheduled, -> {where(scheduled: false)}


  def self.create(attributes = nil, &block)
    user = attributes[:user] 
    if !user.is_system
      super
    end  
  end



  def self.insert(user,service,controller,method,attribute)
    if attribute == nil
      attribute = 0
    end
    logger.debug "****** IN S E R T *********"
    logger.debug user.to_s 
    logger.debug service.to_s
    logger.debug controller.to_s
    logger.debug method.to_s
    logger.debug attribute.to_s
    selectedScore = GamificationRule.where(action_service: service, action_controller: controller, action_method: method, action_attribute: attribute)
    if selectedScore.present?
      UserAction.create(user: user, gamification_rule: selectedScore.first )
    end
  end

  def self.setAsScheduled(id_act)
    logger.debug "*******************    " + id_act.to_s
    action = UserAction.all.where(id: id_act).first()
    action.update(scheduled: true, scheduled_at: DateTime.now)
  end

end

