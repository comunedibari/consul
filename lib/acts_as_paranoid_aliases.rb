module ActsAsParanoidAliases

  def self.included(base)
    base.extend(ClassMethods)
    class_eval do

      def hide
        # new_mod
        if self.class.name == 'User' || self.class.name == 'UserInvestment' || self.class.name == 'CrowdfundingReward'
          update_attribute(:hidden_at, Time.current)
        else 
          update_attribute(:moderation_entity, 3)
        end
        after_hide
      end

      def hidden?
        deleted?
      end

      def after_hide
      end

      def confirmed_hide?
        if self.class.name == 'User'
          confirmed_hide_at.present?
        else
          moderation_entity == 4
        end
      end

      def approved_hide?
        if self.class.name == 'User'
          confirmed_hide_at.present?
        else
          confirmed_hide_at.present? && flags_count >= 0
        end
      end

      def confirm_hide 
        #logger.debug "---------------confirm_hide"
        if self.class.name == 'User'
          update_attribute(:confirmed_hide_at, Time.current)
        else
          update_attribute(:moderation_entity, 4)
        end
      end

      def reset_flags_count
        if try(:moderation_entity)
          update_attribute(:moderation_entity, 1)
        end
        if try(:ignored_flag_at)
          if flags_count > 0
            update_attribute(:ignored_flag_at, Time.current)
          end 
        end
        after_restore
      end

      def restore(opts = {})                
        #logger.debug "---------------restore"
        update_attribute(:moderation_date, Time.current)
        #return false unless hidden?
        super(opts)
        if try(:confirmed_hide_at)
          update_attribute(:confirmed_hide_at, nil)
        end
        if try(:moderation_entity)
          update_attribute(:moderation_entity, 1)
        end
        if try(:flags_count)
          update_attribute(:flags_count, 0)
        end
        if try(:ignored_flag_at)
          update_attribute(:ignored_flag_at, nil)
        end
        after_restore
      end

      def after_restore
      end
    end
  end

  module ClassMethods
    
    def new_mod_hidden
      where("moderation_entity = 3").where.not(confirmed_hide_at: nil)
    end

    def with_confirmed_hide
      if self == User
        where.not(confirmed_hide_at: nil)
      else
        rejected_by_admin
      end
    end

    def all_admin
      if self == User
        #REVISE!
        where(confirmed_hide_at: nil)
      else
        mod_pending_admin
      end
    end

    # rejected by moderator
    def without_confirmed_hide
      if self == User
        where(confirmed_hide_at: nil)
      else
        rejected_by_mod
       
      end
    end

    def with_hidden
      with_deleted
    end

    def only_hidden
      only_deleted
    end

    def hide_all(ids)
      return if ids.blank?
      where(id: ids).each(&:hide)
    end

    def restore_all(ids)
      return if ids.blank?
      only_hidden.where(id: ids).each(&:restore)
    end
  end
end
