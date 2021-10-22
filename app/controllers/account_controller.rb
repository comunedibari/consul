class AccountController < ApplicationController
  before_action :set_account
  load_and_authorize_resource class: "User", :except => [:setPrivacy]
  skip_authorization_check :only => [:setPrivacy]


  extend ActiveSupport::Concern

  #mie modifiche mappa
  before_action :load_categories, only: [:map]
  before_action :load_geozones, only: [:edit, :map]
  before_action :authenticate_user!, except: [:map, :large_map]
  before_action :destroy_map_location_association, only: :update
  before_action :update_email_notifications, only: :update
  #fine

  def show
    if current_user.provider == 'openam'
      if Rails.env.production? && Rails.application.config.cm == 'cm1'
        setPrivacyInfoSession
        #else
        #  session["consensoPrivacy"] = true
        #  session["consensoPrivacyGeo"] = true
      end
    end
    #@checked_consensoPrivacy = session["consensoPrivacy"]
    #@checked_consensoPrivacyGeo =  session["consensoPrivacyGeo"]

    #add breadcrumb in account
    add_breadcrumb t('breadcrumbs.services.account')
  end

  def setPrivacyInfoSession

    logger.debug "*********** setPrivacyInfoSession **************"
    begin
      response = RestClient::Request.execute(
          method: :get,
          verify_ssl: false,
          cookies: {:iPlanetDirectoryPro => cookies[:iPlanetDirectoryPro]},
          url: "#{Rails.application.config.privacy_geo}/autoregistrazione/rest/user/userPrivacy",
          headers: {:content_type => "application/json"})

      json_response = JSON.parse(response)

      #session["consensoPrivacy"] = json_response["consensoPrivacy"]
      #session["consensoPrivacyGeo"] = json_response["consensoPrivacyGeo"]

      @account.privacy = json_response["consensoPrivacy"] && json_response["consensoPrivacyGeo"]
      @account.save

        #logger.debug "consensoPrivacy =" + session["consensoPrivacy"].to_s
        #logger.debug "consensoPrivacyGeo =" + session["consensoPrivacyGeo"].to_s
        #logger.debug "*****************************************"

    rescue SocketError => e
      logger.error "----------In Socket errror"
      logger.error e.to_s
      redirect_to :back, :flash => {:alert => t('reportings.index.featured_reportings_error')}
    rescue => e
      logger.error "----------In E errror"
      logger.error e.to_s
      redirect_to :back, :flash => {:alert => t('reportings.index.featured_reportings_error')}
        #raise
    rescue RestClient::Exception => e
      logger.error e.http_body
      logger.error e.to_s
      redirect_to :back, :flash => {:alert => t('reportings.index.featured_reportings_error')}
    end

    #for testing TO REMOVE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|
    #session["consensoPrivacy"] = true
    #session["consensoPrivacyGeo"] = true

  end

  def setPrivacy

    if @account.save
      if Rails.env.production? && Rails.application.config.cm == 'cm1' && @account.provider == 'openam'
        # chekc malformed request
        p_consensoPrivacy = params[:privacy].present? #params[:consensoPrivacy].present?
        p_consensoPrivacyGeo = p_consensoPrivacy #params[:consensoPrivacyGeo].present?

        json_payload = {"consensoPrivacy" => p_consensoPrivacy, "consensoPrivacyGeo" => p_consensoPrivacyGeo}

        logger.debug "************ setPrivacy checkbox-values *************"
        logger.debug "******* payload:"
        logger.debug json_payload.to_json
        logger.debug "**************************************"


        begin
          response = RestClient::Request.execute(
              method: :post,
              verify_ssl: false,
              #cookies: {:iPlanetDirectoryPro => 'AQIC5wM2LY4SfcwwyKCpwfeKjub4JYLmEYKOiT3Lyz9bOF0.*AAJTSQACMDIAAlNLABQtNjM1MTgwNDEwOTQ4MjE2MzAwOAACUzEAAjAx*'},
              cookies: {:iPlanetDirectoryPro => cookies[:iPlanetDirectoryPro]},
              url: "#{Rails.application.config.privacy_geo}/autoregistrazione/rest/user/userPrivacy",
              headers: {'Content-Type' => "application/json"},
              payload: json_payload.to_json
          )

          logger.debug "************ setPrivacy response *************"
          logger.debug response.to_s
          logger.debug "*************************************"

          json_response = JSON.parse(response)

          if json_response["result"]["status"] != "KO"
            setPrivacyInfoSession
            #p_consensoPrivacy = params[:privacy].present?
            #@account.privacy = p_consensoPrivacy
            #@account.save
            redirect_to :back, notice: t('notice.operaction_successfull')
          else
            #errore nel servizio di autenticazione privacy
            logger.error "************************   ERRORE NEL SERVIZIO DI AUTENTICAZIONE    *****************************************"
            logger.error response.to_s
            #session["consensoPrivacy"] = true
            #session["consensoPrivacyGeo"] = true
            redirect_to :back, :flash => {:alert => t('reportings.index.featured_reportings_error')}
          end

        rescue SocketError => e
          logger.error "----------In Socket errror"
          logger.error e.to_s
          redirect_to :back, :flash => {:alert => t('reportings.index.featured_reportings_error')}
        rescue => e
          logger.error "----------In E errror"
          logger.error e.to_s
          redirect_to :back, :flash => {:alert => t('reportings.index.featured_reportings_error')}
            #raise
        rescue RestClient::Exception => e
          logger.error e.http_body
          logger.error e.to_s
          redirect_to :back, :flash => {:alert => t('reportings.index.featured_reportings_error')}
        end
      else
        p_consensoPrivacy = params[:privacy].present?
        @account.privacy = p_consensoPrivacy
        @account.save
        #session["consensoPrivacy"] = true
        #session["consensoPrivacyGeo"] = true
        redirect_to :back, notice: t('notice.operaction_successfull')
      end
    else
      redirect_to :back, alert: t("form.not_sended_html")
    end
  end

  def preferences

    @user_tags = Array.new
    user_tags_selected = UserTag.where(user_id: current_user.id).pluck(:tag_id)
    if user_tags_selected.count == 0
      @tags = ActsAsTaggableOn::Tag.category
    else
      @tags = ActsAsTaggableOn::Tag.category.where('id not in (?)', user_tags_selected)
    end


    UserTag.where(user_id: current_user.id).each do |t|
      t.selected = true
      @user_tags.push(t)
    end
    @tags.each do |t|
      o = UserTag.new(user: current_user, tag: t)
      o.selected = false
      @user_tags.push(o)
    end
  end

  def update
    if @account.update(account_params.except(:email_global_notifications))
      #modifiche mappa
      if Rails.application.config.coord_user_address && params[:account][:skip_map].to_i == 1 && @account.map_location
        MapLocation.destroy(@account.map_location.id)
      end
      #fine

      redirect_to account_path, notice: t("flash.actions.save_changes.notice")
    else
      @account.errors.messages.delete(:organization)
      render :show
    end
  end

  private

  # Aggiornamento dei campi di notifica mail in base al settaggio globale da interfaccia grafica
  def update_email_notifications

    if account_params[:email_global_notifications].present?

      case account_params[:email_global_notifications]
      when "0"
        setting = false
      when "1"
        setting = true
      else
        setting = false
      end

      # Modifico tutti i campi che devono essere modificati dal setting globale
      @account.email_global_notifications_fields.each do |field_name|
        @account[field_name] = setting
      end

      # email_global_notifications NON fa parte del model, quindi và eliminato prima dell'update
      account_params.extract!(:email_global_notifications)
    end

  end

  def set_account
    @account = current_user
  end

  def account_params
    if Rails.application.config.coord_user_address
      attributes = if @account.organization?
                     [:phone_number, :email_on_comment, :email_on_comment_reply, :newsletter,
                      :address,
                      :skip_map,
                      :public_map,
                      map_location_attributes: [:latitude, :longitude, :zoom, :address]] #modifica mappa
                   else
                     [:username, :public_activity, :public_interests, :email_on_comment,
                      :email_on_comment_reply, :email_on_direct_message, :email_digest, :newsletter,
                      :official_position_badge,
                      :address,
                      :skip_map,
                      :public_map,
                      map_location_attributes: [:latitude, :longitude, :zoom]] #modifica mappa
                   end
    else
      attributes = if @account.organization?
                     [:phone_number, :email_on_comment, :email_on_comment_reply, :newsletter,
                      :address,
                      :skip_map,
                      :public_map]
                   else
                     [:username, :public_activity, :public_interests, :email_on_comment,
                      :email_on_comment_reply, :email_on_direct_message, :email_digest, :newsletter,
                      :official_position_badge,
                      :skip_map,
                      :public_map,
                      :address]
                   end
    end
    #params.require(:account).permit(*attributes, :consensoPrivacyGeo, :consensoPrivacy, :privacy)
    params.require(:account).permit(*attributes, :privacy, :email_global_notifications)
  end

  #modifiche mappa
  def large_map
    @accounts = @accounts.by_user_pon
  end

  #modifiche mappa

  def destroy_map_location_association
    if Rails.application.config.coord_user_address
      map_location = params[:account][:map_location_attributes]
      skip_map = params[:account][:skip_map]
      if skip_map == "1" || (map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?)
        MapLocation.destroy(map_location[:id])
      end
    end
  end
end
