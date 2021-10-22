class Admin::BookingManager::BaseController < Admin::BaseController
  helper_method :namespace

  private

    def verify_administrator
      raise CanCan::AccessDenied unless current_user.try(:administrator?) || current_user.try(:moderator?)
    end

    def namespace
      "admin"
    end

end
