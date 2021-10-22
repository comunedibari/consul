
require File.expand_path('../boot', __FILE__)

require "csv"
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Consul
  class Application < Rails::Application


    config.log_tags = [
      '',
      ->(req) {
        session_key = (Rails.application.config.session_options || {})[:key]
        session_data = req.cookie_jar.encrypted[session_key] || {}

        if session_data["warden.user.user.key"]
          user_id = session_data["warden.user.user.key"][0]
        else
          user_id = "guest"
        end

        "user: #{user_id.to_s}" + "    #{req.ip}" + "    #{req.remote_ip} " + "    #{req.env['HTTP_X_FORWARDED_FOR']}"
      }
    ]



    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.i18n.available_locales = [:en, :es, :fr, :nl, 'pt-BR']
    config.i18n.fallbacks = {'fr' => 'es', 'pt-br' => 'es', 'nl' => 'en'}
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'custom', '**', '*.{rb,yml}')]

    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Add lib to the autoload path
    config.autoload_paths << Rails.root.join('lib')
    config.time_zone = 'Madrid'

    config.time_zone = 'Rome'
    config.i18n.default_locale = :it
    config.i18n.available_locales = [:it, :en]
    config.i18n.fallbacks = {'it' => 'en'}

    #INIZIO CONFIGURAZIONE CORE

    config.cm = 'cm1'   # context_management da utilizzare per installazione/seeding/customizzazione
    #config.cm = 'cm2'   # context_management da utilizzare per installazione/seeding/customizzazione


    # esecuzione dei job per eventi asincorni portale (notifiche, upload file)
    config.jobs_execution = true

    # abilita l'esecuzione all'avvio, dei job di migrazione da SGAP e BIS
    config.migration_job = true

    #FINE CONFIGURAZIONE CORE


    # CONSUL specific custom overrides
    # Read more on documentation:
    # * English: https://github.com/consul/consul/blob/master/CUSTOMIZE_EN.md
    # * Spanish: https://github.com/consul/consul/blob/master/CUSTOMIZE_ES.md
    #
    config.autoload_paths << "#{Rails.root}/app/controllers/custom/#{config.cm}"
    config.autoload_paths << "#{Rails.root}/app/models/custom/#{config.cm}"
    config.paths['app/views'].unshift(Rails.root.join('app', 'views', 'custom', config.cm))
    config.i18n.load_path += Dir[Rails.root.join('config', 'custom', config.cm,  'locales', '*.{rb,yml}')]
    config.layout = config.cm
    config.css = config.cm +'.css'

    #attiva salvataggio map_location su users
    config.coord_user_address = true

    #Tipi di file accettati come documenti
    config.docs_content_types = ["application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword","application/zip"]
    #Tipi di estensioni relative ai tipi di file accettati come documenti
    config.docs_extension_types = ["pdf","docx","doc","zip"]

    #Tipi di file accettati come immagini
    config.images_content_types =  %w(image/jpeg image/jpg image/png)

    config.active_job.queue_adapter = :sidekiq

    if defined?(Rails::Server)
      config.after_initialize do
        RecoverTagNotificationsJob.perform_now
        #GamificationHourlyJob.perform_later
        #GamificationMonthlyJob.perform_later

        if config.migration_job
        #Abilita l'esecizione del job caricamento progetti SGAP e BIS
          #SgapDownloadDataJob.perform_later
          #BisDownloadDataJob.perform_later
          #BisProcessDownloadDataJob.perform_later
          #RepotingsDataJob.perform_later
          #AllRepotingsDataJob.perform_later
          #if Reporting.all.count == 0
          #  RepotingsDataJob.perform_later
          #end
        end
      end
    end

  Paperclip.options[:command_path] = "/usr/local/bin/identify"

  end
end

require "./config/custom/"+Rails.application.config.cm+"/application_custom.rb"
