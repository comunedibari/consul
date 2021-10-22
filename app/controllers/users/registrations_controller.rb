require 'net/http'
require 'uri'

class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :authenticate_scope!, only: [:edit, :update, :destroy, :finish_signup, :do_finish_signup]
  before_filter :configure_permitted_parameters

  invisible_captcha only: [:create], honeypot: :family_name, scope: :user

  def new
    super do |user|
      user.use_redeemable_code = true if params[:use_redeemable_code].present?
    end
  end

  def create
    build_resource(sign_up_params)
    if resource.valid?
      super
    else
      render :new
    end
  end

  def delete_form
    build_resource({})
  end

  def delete

    #if current_user.provider == 'openam'
    #  delete_jim_user(current_user.cod_fiscale)
    #end

    current_user.erase(erase_params[:erase_reason])
    delete_user_id_from_sector
    sign_out
    #Per il contest CM1 viene cancellato il cookie di openam
    if Rails.application.config.cm == 'cm1'
      cookies.delete(:iPlanetDirectoryPro, domain: Rails.application.config.cookie_domain)
    end
    #if idp.present? && idp.provider == 'shibboleth'
    #  redirect_to Rails.application.config.spid_logout_url, notice: t("devise.registrations.destroyed")
    #else
    redirect_to root_url, notice: t("devise.registrations.destroyed")
    #end
    #if idp.present? && idp.provider == 'openam'
    #  redirect_to Rails.application.config.openam_logout_url, notice: t("devise.registrations.destroyed")
    #else
    #  redirect_to root_url, notice: t("devise.registrations.destroyed")
    #end
  end

  def delete_user_id_from_sector
    sectors = Sector.where(user_id: current_user.id)
    st_sectors = StSector.where(user_id: current_user.id)
    if sectors.count > 0
      sectors.each do |sector|
        sector.user_id = nil
        sector.save
      end
      st_sectors.each do |st_sector|
        st_sector.user_id = nil
        st_sector.save
      end
    end
  end

  def success
  end

  def finish_signup
    current_user.registering_with_oauth = false
    current_user.email = current_user.oauth_email if current_user.email.blank?
    current_user.validate
  end

  def do_finish_signup
    current_user.registering_with_oauth = false
    if current_user.update(sign_up_params)
      current_user.send_oauth_confirmation_instructions
      sign_in_and_redirect current_user, event: :authentication
    else
      render :finish_signup
    end
  end

  def check_username
    if User.find_by username: params[:username]
      render json: { available: false, message: t("devise_views.users.registrations.new.username_is_not_available") }
    else
      render json: { available: true, message: t("devise_views.users.registrations.new.username_is_available") }
    end
  end

  private

  def unique_document_number
    @document_number ||= 12345678
    @document_number += 1
    "#{@document_number}#{[*'A'..'Z'].sample}"
  end

  def sign_up_params
    params[:user].delete(:redeemable_code) if params[:user].present? && params[:user][:redeemable_code].blank?

    if Rails.application.config.cm == "cm2"
      params[:user].delete(:redeemable_code) if params[:user].present? && params[:user][:redeemable_code].blank?
      params.require(:user).permit(:username, :email, :password,
                                   :password_confirmation, :terms_of_service, :locale,
                                   :redeemable_code).merge(pon_id: 1, geozone_id: 1, skip_map: "1",
                                                           verified_at: Time.current, document_type: "1",
                                                           document_number: unique_document_number)
    else
      params.require(:user).permit(:username, :email, :password,
                                   :password_confirmation, :terms_of_service, :locale,
                                   :redeemable_code)
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update).push(:email)
  end

  def erase_params
    params.require(:user).permit(:erase_reason)
  end

  def after_inactive_sign_up_path_for(resource_or_scope)
    users_sign_up_success_path
  end

  def delete_jim_user(cod_fiscale)
    begin
      uri = URI.parse("#{Rails.application.config.url_delete}/idm/rest/service/users/" + cod_fiscale)
      request = Net::HTTP::Delete.new(uri)
      request.basic_auth(Rails.application.config.jim_user, Rails.application.config.jim_password)
      request.content_type = "application/json"
      request["Accept"] = "application/json"

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      Rails.logger.info "-----#{response.code}"
      Rails.logger.info "-----#{response.body}"

    rescue => e
      logger.error "----------E error----------------------------------"
      logger.error e.to_s
      logger.error response.to_s
    end

  end

end
