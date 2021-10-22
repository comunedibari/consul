class GamificationServiceResult < ActiveRecord::Base

  belongs_to :user

  scope :sort_by_global_partial_results, ->(service) { where(:service  => service ).where("current_month_result >= 0") }
  scope :reorder_sort_by_global_partial_results, -> {reorder(current_month_result: :desc)}

  scope :sort_by_global_partial_results_user, ->(service) { where(:service  => service ) }
  scope :sort_by_global_partial_results_by_user, ->(user) {where("user_id =? ",user ) }


  scope :sort_by_current_month, ->(service) { where(:service  => service ).where("current_month_result > 0").reorder(current_month_result: :desc) }
  scope :sort_by_prec_month,    ->(service) { where(:service  => service ).where("prec_month_result > 0").reorder(prec_month_result: :desc) }
  scope :sort_by_total,         ->(service) { where(:service  => service ).where("total_result > 0").reorder(total_result: :desc) }



  def self.increse_value(user_id,service,value)
    serviceResult = GamificationServiceResult.find_or_create_by(user_id:user_id,service:service)
    serviceResult.update_attribute(:current_month_result,serviceResult.current_month_result+value)
    serviceResult.update_attribute(:total_result,serviceResult.total_result+value)
    result = GamificationResult.find_or_create_by(user_id:user_id)
    result.update_attribute(:total_stats,result.total_stats+value)
    result.update_attribute(:current_month_stats,result.current_month_stats+value)
  end

  def self.update_stats(id)
    serviceResult = GamificationServiceResult.find(id)
    serviceResult.update_attribute(:prec_month_result,serviceResult.current_month_result)
    serviceResult.update_attribute(:current_month_result, 0 )
  end



  def self.assign_badges

    UserAction.unscheduled.each do |action|
      user = action.user
      
      logger.debug "User: " + user.id.to_s

      num_contents = user.contents_created
      logger.debug "num_contents: " + num_contents.to_s

      num_comments = user.comments.mod_approved.count
      logger.debug "num_comments: " + num_comments.to_s 

      num_votes = user.votes.count
      logger.debug "num_votes: " + num_votes.to_s
      logger.debug "---------------------------------------------"


      if num_comments > 1 && num_comments <= 5
        insert_badge(user, 1)
      end
      if num_comments > 5 && num_comments <= 10
        insert_badge(user,2) 
      end
      if num_comments > 10 && num_comments <= 15
        insert_badge(user,3) 
      end
      if num_comments > 15
        insert_badge(user,4)
      end


      if num_contents > 1 && num_contents <= 6
        insert_badge(user,6)  
      end
      if num_contents > 6 && num_contents <= 10
        insert_badge(user,7)  
      end
      if num_contents > 10 && num_contents <= 15
        insert_badge(user,8)  
      end
      if num_contents > 15
        insert_badge(user,9)  
      end


      if num_votes > 1 && num_votes <= 5
        insert_badge(user,11) 
      end
      if num_votes > 5 && num_votes <= 10
        insert_badge(user,12) 
      end
      if num_votes > 10 && num_votes <= 15
        insert_badge(user,13)
      end
      if num_votes > 15
        insert_badge(user,14) 
      end



    end

  end


  private

    def self.insert_badge(user, badge_id)
      if user.badges.select{ |item| item.id == badge_id }.count == 0
        user.add_badge(badge_id) 
        #badge_data = Time.current
      end
    end


end
