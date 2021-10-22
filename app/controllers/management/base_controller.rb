class Management::BaseController < ApplicationController
  layout 'admin'

  before_action :authenticate_user!
  before_action :verify_manager
  before_action :set_locale

  skip_authorization_check
  
  helper_method :managed_user


  private

    def verify_manager
      raise CanCan::AccessDenied unless current_user.try(:manager?) || current_user.try(:administrator?)
    end


    def current_manager
      session[:manager]
    end


    def managed_user
      @managed_user ||= Verification::Management::ManagedUser.find(session[:document_type], session[:document_number])
    end

    def check_verified_user(alert_msg)
      unless managed_user.level_two_or_three_verified?
        redirect_to management_document_verifications_path, alert: alert_msg
      end
    end

    def set_locale
      if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
        session[:locale] = params[:locale]
      end

      session[:locale] ||= I18n.default_locale

      I18n.locale = session[:locale]
    end

    def current_budget
      Budget.current
    end

    def clear_password
      session[:new_password] = nil
    end
end

