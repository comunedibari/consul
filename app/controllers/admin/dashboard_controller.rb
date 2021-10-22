class Admin::DashboardController < Admin::BaseController


  def verify_administrator
    if current_user.pon_id != User.pon_id
      raise CanCan::AccessDenied
    end
  end

  def index
  end

end