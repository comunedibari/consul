class Users::SessionsController < Devise::SessionsController
  def create
    super
    flash.delete(:notice)
  end

  def destroy
    #Per il contest CM1 viene cancellato il cookie di openam
    if Rails.application.config.cm == 'cm1'
      cookies.delete(:iPlanetDirectoryPro, domain: Rails.application.config.cookie_domain)
      session["consensoPrivacy"]=nil
      session["consensoPrivacyGeo"]=nil
      
    end
    super
    flash.delete(:notice)
  end


  #Abbiamo riscritto il metodo di Devise::SessionsController
  def respond_to_on_destroy
    respond_to do |format|
      format.all { head :no_content }
      format.any(*navigational_formats) { 
        redirect_to root_path 
      }
    end
  end

  private

  def after_sign_in_path_for(resource)
    session[:pon_id] = current_user.pon_id
    if !verifying_via_email? && resource.show_welcome_screen?
      welcome_path
    else
      super
    end
  end

  def after_sign_out_path_for(resource)
    return Rails.application.config.openam_logout_url if @idp.present? && @idp.provider == 'openam'
    request.referer.present? ? request.referer : super
  end

  def verifying_via_email?
    return false if resource.blank?
    stored_path = session[stored_location_key_for(resource)] || ""
    stored_path[0..5] == "/email"
  end

end
