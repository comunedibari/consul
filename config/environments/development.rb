Rails.application.configure do
  BetterErrors::Middleware.allow_ip! "0.0.0.0/0"
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  #config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = {host: '127.0.0.1', port: 3000}
  config.action_mailer.asset_host = "http://127.0.0.1:3000"
  config.web_console.whitelisted_ips = '10.78.128.0/24'

  # Deliver emails to a development mailbox at /letter_opener
  #config.action_mailer.delivery_method = :letter_opener



  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
      :address => 'smtp',
      :port => 1025,
      :enable_starttls_auto => true,
      :ssl => false,
      :openssl_verify_mode => 'none'
  }


  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  #If you must use the "assets" route then you need to give Asset Pipeline another mount point by adding the following line in your development.rb
  #config.assets.prefix = '/assetz'

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.log_level = :info
  config.cache_store = :dalli_store

  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    if ENV['BULLET']
      Bullet.rails_logger = true
      Bullet.add_footer = true
    end
  end

  if Rails.application.config.environment_set == 'coll'
    config.openam_logout_url = 'openam_logout_url'
  else
    config.openam_logout_url = 'openam_logout_url'
  end

end
