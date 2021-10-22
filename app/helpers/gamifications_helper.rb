module GamificationsHelper

  def gamification_result(resources)
    GamificationServiceResult.sort_by_global_partial_results(resources).reorder_sort_by_global_partial_results
  end


  def gamification_result_user(resources,user)
    GamificationServiceResult.sort_by_global_partial_results(resources).sort_by_global_partial_results_by_user(user.id)
  end

  def get_user()
    if params[:user_id] && params[:user_id] != ''
      user = User.where(id: params[:user_id]).first
    elsif current_user
      user = User.find(current_user.id)
    elsif
      nil
    end
  end

  def get_user_by_id(id_user)
    user = User.where(id: id_user).first
  end

  def check_user_admin_mod?(user)
    !Administrator.unscoped.where(user_id: user.id).presence && !Moderator.unscoped.where(user_id: user.id).presence
  end

  # def gamification_global_result
  #   if @current_order == "current_month"
  #     GamificationResult.sort_by_current_month
  #   elsif @current_order == "prec_month" 
  #     GamificationResult.sort_by_prec_month
  #   elsif @current_order == "total"
  #     GamificationResult.sort_by_total
  #   end
  # end

end