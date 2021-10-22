module Moderable
  extend ActiveSupport::Concern


    def approved?
      if moderation_entity == 1 || moderation_entity == nil
        true
      else
        false
      end    
    end

    #verifico se il dibattito è in attesa di moderazione perchè appena creata
    def in_approval?
      if moderation_entity == 2
        true
      else
        false
      end    
    end

    def rejected?
      if moderation_entity == 3 || moderation_entity == 4
        true
      else
        false
      end    
    end
  
    def load_entity?(user)

      return true if approved? || moderation_entity == nil

      if user 
        if user.administrator?
          return true
        end
        if user.moderator? &&  in_approval?
          return true
        end
        if author==user && in_approval?
          return true
        end  
      end

      return false

    end
    
    

  included do

    #user visible
    scope :mod_approved,     ->   { where("moderation_entity in (1) or moderation_entity is NULL") }
    # mod visibility
    scope :mod_pending, -> { where("moderation_entity in (2,3,4)")}
    scope :mod_pending_moderator, -> { where("moderation_entity in (2)")}
    scope :mod_pending_admin, -> { where("moderation_entity in (3,4)")}

    # admin visible
    scope :rejected_by_mod, -> { where("moderation_entity in (3)")}
    scope :rejected_by_admin, -> { where("moderation_entity in (4)")}
    

  end  

  class_methods do


  end

end
