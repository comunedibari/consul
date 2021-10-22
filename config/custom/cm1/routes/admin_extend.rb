
namespace :admin, path: 'gestione' do

  resources :crowdfundings, path: '/crowdfundings' do
    member do
      get :investments, path: 'investimenti'
      get :rewards, path: 'ricompense'
      get :toedit, path: 'toedit'
    end
    resources :questions, path: 'domande'
    resources :draft_versions, path: 'bozze'
    resources :crowdfunding_rewards, path: '/ricompense' do
      member do
        put :hide
      end
    end
  end


  namespace :collaboration, path: 'patti_di_collaborazione' do
    resources :agreements, path: '/dettaglio' do
      resources :agreement_requirements, path: 'domande'
      resources :subscriptions, path: 'adesioni'
    end
  end

  namespace :legislation, path: 'progetti' do

    resources :processes, path: '/dettaglio' do
      resources :questions, path: 'domande'
      resources :proposals, path: 'proposte', constraints: RoleRouteConstraint.new
      resources :draft_versions, path: 'bozze', constraints: RoleRouteConstraint.new
    end

    resources :processes, path: '/lavori_pubblici', controller: :process_works, as: 'process_works' do
      resources :questions, path: 'domande'
      resources :proposals, path: 'proposte'
      resources :draft_versions, path: 'bozze'
    end

    resources :processes, path: '/opportunita', controller: :process_chances, as: 'process_chances' do
      resources :questions, path: 'domande'
      resources :proposals, path: 'proposte'
      resources :crowdfundings, path: 'proposte'
      resources :draft_versions, path: 'bozze'
    end

    resources :processes, path: '/proposte_e_iniziative', controller: :process_processes_proposals, as: 'process_processes_proposals' do
      resources :questions, path: 'domande'
      resources :proposals, path: 'proposte'
      resources :crowdfundings, path: 'proposte'
      resources :draft_versions, path: 'bozze'
    end

    resources :processes, path: '/categorie_proposte', controller: :process_typologies , as: 'process_typologies' do
    end
  end
end
