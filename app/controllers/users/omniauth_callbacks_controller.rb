class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  #$ponID = 100
  $ponID = 5

  def twitter
    sign_in_with :twitter_login, :twitter
  end

  def facebook
    sign_in_with :facebook_login, :facebook
  end

  def google_oauth2
    sign_in_with :google_login, :google_oauth2
  end

  def shibboleth
    sign_in_with :shibboleth_login, :shibboleth
  end

  def openam
    sign_in_with :openam_login, :openam
  end

  def after_sign_in_path_for(resource)
    #if resource.registering_with_oauth
      #finish_signup_path
    #else
      super(resource)
    #end
  end

  private


    def getPrivacyInfo
      if Rails.env.production? && Rails.application.config.cm == 'cm1'          
        begin
          response = RestClient::Request.execute(
            method: :get, 
            verify_ssl: true,
            cookies: {:iPlanetDirectoryPro => cookies[:iPlanetDirectoryPro]},
            url: "#{Rails.application.config.privacy_geo}/autoregistrazione/rest/user/userPrivacy",  
            headers: { :content_type => "application/json"})
      
          json_response = JSON.parse(response)

          #session["consensoPrivacyGeo"] = json_response["consensoPrivacyGeo"]
          #session["consensoPrivacy"] = json_response["consensoPrivacy"]
          
          @account.privacy = json_response["consensoPrivacy"] && json_response["consensoPrivacyGeo"]
          @account.save

          #logger.debug session["consensoPrivacyGeo"].to_s
          #logger.debug session["consensoPrivacy"].to_s
        rescue => e
          logger.error e.to_s
          logger.error response.to_s
        end
      #else
      #  session["consensoPrivacyGeo"] = true
      #  session["consensoPrivacy"] = true
      end

    end

    def check_user_blocked?(auth)

      id_check = Identity.where(uid: auth.uid, provider: auth.provider)
      if id_check.count > 0
        user_check = User.with_hidden.where(id: id_check.first.user_id).first
        if !user_check.hidden_at.nil?
          logger.info "Utente bloccato" + user_check.hidden_at.to_s + "-"
          return true
        end
      end
      return false

    end

    def sign_in_with(feature, provider)
      #raise ActionController::RoutingError.new('Not Found') unless Setting["feature.#{feature}",current_user.pon_id]
      
      auth = env["omniauth.auth"]

      if check_user_blocked?(auth)
          redirect_to root_path, alert: "Impossibile accedere: utente bloccato" and return
      end
        

      identity = Identity.first_or_create_from_oauth(auth)
      #ci entro solo se faccio un accesso tramite social o openam
      if provider != 'openam'   #siccome nel caso openam sono considerato utente SPID,lo escludo
        session["provider"] = provider  #se sono social mi setto il parametro in sessione e vedrà l'application_controller
      end

      

      @user = current_user || identity.user || User.first_or_initialize_for_oauth(auth)
      
      if Rails.application.config.cm == 'cm2'
        $ponID = 1
      end

      if provider.to_s == 'openam'
        #$ponID = auth.extra.raw_info.ponId[0]  ? auth.extra.raw_info.ponId[0] : 0
        #$ponID = defined?(auth.extra.raw_info.ponId[0]) ? auth.extra.raw_info.ponId[0] : 100
        $ponID = defined?(auth.extra.raw_info.ponId[0]) ? auth.extra.raw_info.ponId[0] : 5

        if !defined?(auth.extra.raw_info.ponId[0]) || auth.extra.raw_info.ponId[0] == 0

          if defined?(auth.extra.raw_info.comuneResidenza) && Pon.where(cod_belfiore: auth.extra.raw_info.comuneResidenza).count > 0
            $ponID = Pon.where(cod_belfiore: auth.extra.raw_info.comuneResidenza).first.id
            logger.info "///////////////******************* COMUNE DI RESIDENZA ***************************////////" +  auth.extra.raw_info.comuneResidenza.to_s
          end
        end
        getPrivacyInfo
        logger.info "///////////////******************* OGGETTO AUTH ***************************////////" + auth.to_s
      else
        #$ponID = 100
        $ponID = 5
        logger.info "///////////////******************* OGGETTO AUTH ***************************////////" + auth.to_s
      end

      #auth.extra.raw_info.comuneResidenza

      if provider.to_s == 'facebook' || provider.to_s == 'twitter' || provider.to_s == 'google_oauth2'
        session["social_access"] = TRUE
      else
        session["social_access"] = FALSE
      end

      if save_user
        logger.debug "ENTRO IN SAVE USER"
        logger.debug $ponID.to_s
        identity.update(user: @user)

        #Inserisco il pon id da openam
        @user.update_columns(pon_id: $ponID)
        @user.update_columns(verified_at: Time.current)
        @user.update_columns(residence_verified_at: Time.current)
        
        #cod_fiscale = @user.cod_fiscale ? @user.cod_fiscale.upcase : ""
        #@user.update_columns(cod_fiscale: cod_fiscale)
        
        #se è un utente SPID -> associio l'utente ad eventuali associazioni
        if provider.to_s == 'openam'
          @user.set_sector_for_user
        end

        sign_in_and_redirect @user, event: :authentication

        kind_msg = provider.to_s.capitalize
        Rails.logger.info "provider: #{provider}"
        
        if provider.to_s == 'shibboleth'
          kind_msg = auth.info.idp
        end

        if provider.to_s == 'openam'
          kind_msg = auth.info.idp
        end

        if provider.to_s == 'openam'
          kind_provider = "" #"openam o SPID"
        else
          kind_provider = " mediante " + provider.to_s.capitalize
        end
        kind_provider = ""
        
        set_flash_message(:notice, :success, kind: kind_provider) if is_navigational_format?
      else
        session["devise.#{provider}_data"] = auth
        redirect_to new_user_registration_url
      end

    end

    def save_user
      @user.save || @user.save_requiring_finish_signup
    end

end
