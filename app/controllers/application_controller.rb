require "application_responder"

class ApplicationController < ActionController::Base
  include HasFilters
  include HasOrders
  include ApplicationHelper

  before_action :authenticate_http_basic, if: :http_basic_auth_site?

  before_action :ensure_signup_complete
  before_action :set_locale
  before_action :track_email_campaign
  before_action :set_return_url
  before_action :set_pon_id

  check_authorization unless: :devise_controller?
  self.responder = ApplicationResponder

  protect_from_forgery with: :exception

  #home breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.home"), :root_path

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html {redirect_to main_app.root_url, alert: exception.message}
      format.json {render json: {error: exception.message}, status: :forbidden}
    end
  end

  layout :set_layout
  respond_to :html
  helper_method :current_budget
  before_filter :set_current_user

  if Rails.env.production?
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    #rescue_from Exception, with: :not_found
    rescue_from ActionController::RoutingError, with: :not_found
  end

  def raise_not_found
    raise ActionController::RoutingError.new("No route matches #{params[:unmatched_route]}")
  end

  def not_found
    respond_to do |format|
      format.html {render file: "#{Rails.root}/public/404", layout: false, status: :not_found}
      format.xml {head :not_found}
      format.any {head :not_found}
    end
  end

  def error
    respond_to do |format|
      format.html {render file: "#{Rails.root}/public/500", layout: false, status: :error}
      format.xml {head :not_found}
      format.any {head :not_found}
    end
  end


  protected

  def set_current_user
    if session[:pon_id]
      User.pon_id = session[:pon_id].to_i
    elsif current_user
      User.pon_id = current_user.pon_id
    end
    if current_user
      #setto il provider nel current_user dalla sessione... il paramentro di sessione lo setto in omniauth_callback_controller nella sign_in
      current_user.update(provider: session[:provider])
      if !current_user.provider.present? && !current_user.administrator? && !current_user.moderator?
        current_user.update(provider: 'test')
      end
      # current_user.update(provider: "facebook") #prova nel caso in cui l'utente entra come social con facebook
      # current_user.update(provider: "openam") #prova nel caso in cui l'utente entra come spid con openam
    end

    #if isBlockedPrivacy
    #  if controller_path != 'account' && controller_path != 'users/sessions'
    #    redirect_to account_path
    #  end
    #end

    #settaggi per test
    # session["consensoPrivacy"] = true
    # session["consensoPrivacyGeo"] = true
    # @checked_consensoPrivacy = session["consensoPrivacy"]
    # @checked_consensoPrivacyGeo =  session["consensoPrivacyGeo"]

=begin
      if current_user
        User.current = current_user
        User.pon_id = current_user.pon_id
      end
=end
  end

  private

  def current_ability
    @current_ability ||= Ability.new(current_user, params, isBlockedPrivacy)
  end

  def authenticate_http_basic
    authenticate_or_request_with_http_basic do |username, password|
      username == Rails.application.secrets.http_basic_username && password == Rails.application.secrets.http_basic_password
    end
  end

  def http_basic_auth_site?
    Rails.application.secrets.http_basic_auth
  end

  def verify_lock
    if current_user.locked?
      redirect_to account_path, alert: t('verification.alert.lock')
    end
  end

  def set_pon_id
    if params[:pon_id]
      Pon.ids.each do |id|
        if params[:pon_id].to_i == id
          if Pon.where("id > 0").count == 1
            session[:pon_id] = Pon.where("id > 0").first.id
          else
            session[:pon_id] = params[:pon_id]
          end
        else
          if Pon.where("id > 0").count == 1
            session[:pon_id] = Pon.where("id > 0").first.id
          end
        end
      end
    else
      if !session[:pon_id]
        if current_user
          session[:pon_id] = current_user.pon_id
        else
          if Pon.where("id > 0").count > 1
            session[:pon_id] = Rails.application.config.default_pon
          end
        end
      end
    end
  end

  def set_locale
    if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
      session[:locale] = params[:locale]
    end

    session[:locale] ||= I18n.default_locale

    locale = session[:locale]

    if current_user && current_user.locale != locale.to_s
      current_user.update(locale: locale)
    end

    I18n.locale = locale
  end

  def set_layout
    if devise_controller?
      "devise"
    else
      "application"
    end
  end


  def set_event_votes(events)
    @event_votes = current_user ? current_user.event_votes(events) : {}
  end

  def set_debate_votes(debates)
    @debate_votes = current_user ? current_user.debate_votes(debates) : {}
  end

  def set_crowdfunding_votes(crowdfundings)
    @crowdfunding_votes = current_user ? current_user.crowdfunding_votes(crowdfundings) : {}
  end

  def set_proposal_votes(proposals)
    @proposal_votes = current_user ? current_user.proposal_votes(proposals) : {}
  end

  def set_reporting_votes(reportings)
    @reporting_votes = current_user ? current_user.reporting_votes(reportings) : {}
  end

  def set_spending_proposal_votes(spending_proposals)
    @spending_proposal_votes = current_user ? current_user.spending_proposal_votes(spending_proposals) : {}
  end

  def set_comment_flags(comments)
    @comment_flags = current_user ? current_user.comment_flags(comments) : {}
  end

  def ensure_signup_complete
    if user_signed_in? && !devise_controller? && current_user.registering_with_oauth
      #redirect_to finish_signup_path
    end
  end

  def verify_resident!
    unless current_user.residence_verified?
      redirect_to new_residence_path, alert: t('verification.residence.alert.unconfirmed_residency')
    end
  end

  def verify_verified!
    if current_user.level_three_verified?
      redirect_to(account_path, notice: t('verification.redirect_notices.already_verified'))
    end
  end

  def track_email_campaign
    if params[:track_id]
      campaign = Campaign.where(track_id: params[:track_id]).first
      ahoy.track campaign.name if campaign.present?
    end
  end

  def set_return_url
    if !devise_controller? && controller_name != 'welcome' && is_navigational_format?
      store_location_for(:user, request.path)
    end
  end

  def set_default_budget_filter
    if @budget.try(:balloting?)
      params[:filter] ||= "selected"
    end
  end

  def current_budget
    Budget.current
  end
end
