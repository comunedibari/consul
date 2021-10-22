class CustomFailure < Devise::FailureApp
  def redirect_url
    if Rails.application.config.cm == 'cm1'
      if params
        # login_admin_path
        new_user_session_path
        #root_path
      else
        user_omniauth_authorize_path(:openam)
      end
    else
      user_session_path
    end
  end
  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
