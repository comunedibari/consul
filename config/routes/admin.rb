namespace :admin, path: 'amministrazione' do
  root to: "dashboard#index"
  resources :organizations, only: :index, path: 'organizzazioni' do
    get :search, on: :collection
    member do
      put :verify
      put :reject
    end
  end

  namespace :moderation, path: 'moderazione' do

    resources :hidden_users, only: [:index, :show], path: 'utenti_bloccati' do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :debates, only: :index, path: 'discussioni' do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :proposals, only: :index, path: Rails.application.config.route_proposals do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :crowdfundings, only: :index, path: Rails.application.config.route_crowdfundings do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :reportings, only: :index, path: 'segnalazioni' do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :events, only: :index, path: 'eventi' do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :processes, only: :index, path: 'proposte_e_iniziative' do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :agreements, only: :index, path: 'patti_di_collaborazione' do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :comments, only: :index, path: 'commenti' do
      member do
        put :restore
        put :confirm_hide
      end
    end

    namespace :legislation, path: 'proposte' do
      resources :proposals, only: :index, path: 'proposte_utente' do
        member do
          put :restore
          put :confirm_hide
        end
      end
    end

  end


  resources :spending_proposals, only: [:index, :show, :edit, :update] do
    member do
      patch :assign_admin
      patch :assign_valuators
    end

    get :summary, on: :collection
  end

  resources :budgets do
    member do
      put :calculate_winners
    end

    resources :budget_groups do
      resources :budget_headings
    end

    resources :budget_investments, only: [:index, :show, :edit, :update] do
      resources :budget_investment_milestones
      member {patch :toggle_selection}
    end

    resources :budget_phases, only: [:edit, :update]
  end

  #resources :signature_sheets, only: [:index, :new, :create, :show], path: 'fogli_firme'

#  resources :banners, only: [:index, :new, :create, :edit, :update, :destroy] do
#    collection {get :search}
#  end


  resources :tags, only: [:index, :create, :update, :destroy], path: 'temi'
  resources :officials, only: [:index, :edit, :update, :destroy], path: 'incarichi_pubblici' do
    get :search, on: :collection
  end

  resources :settings, only: [:index, :update], :path => 'impostazioni' do
    collection do
      put :exec_job
    end
  end
  put :update_map, to: "settings#update_map"

  resources :moderators, only: [:index, :create, :destroy], path: 'moderatori' do
    get :search, on: :collection
  end

  resources :valuators, only: [:show, :index, :edit, :update, :create, :destroy], path: 'valutatori' do
    get :search, on: :collection
    get :summary, on: :collection
  end
  resources :valuator_groups, path: 'gruppi_valutatori'

  resources :managers, only: [:index, :create, :destroy], path: 'gestori' do
    get :search, on: :collection
  end

  resources :administrators, only: [:index, :create, :destroy], path: 'amministratori' do
    get :search, on: :collection
  end

  resources :users, only: [:index, :show], path: 'utenti'

  scope module: :poll do
    resources :polls, path: 'consultazioni' do
      get :booth_assignments, on: :collection
      patch :add_question, on: :member

      resources :booth_assignments, only: [:index, :show, :create, :destroy] do
        get :search_booths, on: :collection
        get :manage, on: :collection
      end

      resources :officer_assignments, only: [:index, :create, :destroy] do
        get :search_officers, on: :collection
        get :by_officer, on: :collection
      end

      resources :recounts, only: :index
      resources :results, only: :index
    end

    resources :officers do
      get :search, on: :collection
    end

    resources :booths do
      get :available, on: :collection

      resources :shifts do
        get :search_officers, on: :collection
      end
    end

    resources :questions, shallow: true, path: 'quesiti' do
      resources :answers, path: 'risposte', except: [:index], controller: 'questions/answers' do
        resources :images, controller: 'questions/answers/images', path: 'immagini'
        resources :videos, controller: 'questions/answers/videos', path: 'video'
        get :documents, to: 'questions/answers#documents', path: 'documenti'
      end
      post '/answers/order_answers', to: 'questions/answers#order_answers'  
      collection do
        get :load_question  
        get :load_answer
      end 
      member do
        delete  :delunderquestion
        post    :editunderquestion
        patch   :update_underquestion
      end        
    end
  end
  
  resources :verifications, controller: :verifications, only: :index, path: 'verifiche' do
    get :search, on: :collection
  end

  resource :activity, controller: :activity, only: :show

  #resources :newsletters do
  #  member do
  #    post :deliver
  #  end
  #  get :users, on: :collection
  #end

  #resources :emails_download, only: :index, path: 'download' do
  #  get :generate_csv, on: :collection
  #end

  resource :stats, only: :show, :path => 'statistiche' do
    get :proposal_notifications, on: :collection, path: 'notifiche_' + Rails.application.config.route_proposals
    get :direct_messages, on: :collection, path: 'messaggi_diretti'
#    get :polls, on: :collection, path: 'consultazioni'
  end

  resource :stats, only: :show, :path => 'statistiche' do
    get :crowdfunding_notifications, on: :collection, path: 'notifiche_' + Rails.application.config.route_crowdfundings
    get :direct_messages, on: :collection, path: 'messaggi_diretti'
#    get :polls, on: :collection, path: 'consultazioni'
  end


  namespace :api do
    resource :stats, only: :show
  end

  resources :geozones, only: [:index, :new, :create, :edit, :update, :destroy], path: Rails.application.config.route_geozones

  #namespace :site_customization, path: 'configurazione_portale' do
  #  resources :pages, except: [:show], path: 'pagine'
  #  resources :images, only: [:index, :update, :destroy], path: 'immagini'
  #  resources :content_blocks, except: [:show], path: 'blocchi_contenuto'
  #end
  scope module: :booking_manager do

    resources :assets, path: Rails.application.config.route_assets do
      resources :availabilities, controller: 'availabilities', path: '/disponibilita' do
        resources :day_availability
        collection do
          get 'daily_availability'
          post 'create_daily'
        end
        member do
          post :destroy_daily
        end
      end
      member do
        post :set_rule
      end
    end
    resources :moderable_bookings, path: Rails.application.config.route_reservation do
      member do

      end
    end
  end
end
