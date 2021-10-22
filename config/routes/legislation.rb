
resources :processes, only: [:index, :show], controller: :chances, path: 'opportunita', as: 'chances' do
  collection do
    get :large_map, path: 'dettaglio_mappa'
  end
end

resources :processes, only: [:index, :show], controller: 'processes_proposals', path: 'proposte_e_iniziative', as: 'processes_proposals' do
  collection do
    get :large_map, path: 'dettaglio_mappa'
    get :filter_by_typology # filtro per categoria proposta
  end
end

resources :processes, only: [:index, :show], controller: :works, path: 'lavori_pubblici', as: 'works' do
  collection do
    get :large_map, path: 'dettaglio_mappa'
  end
end

namespace :legislation, path: 'progetti' do

  resources :processes, only: [:index, :show], path: '' do
    member do
      get :debate , path: 'consultazioni'
      get :sgap , path: 'sgap'
      get :draft_publication, path: 'aggiornamenti', constraints: RoleRouteConstraint.new
      get :allegations, path: 'allegati', constraints: RoleRouteConstraint.new
      get :details, path: 'dettaglio'
      get :result_publication, path: 'risultati', constraints: RoleRouteConstraint.new
      get :proposals, path: 'proposte'
      put :flag
      put :unflag
      get :json_data
      get :social_flag, path: 'social'
      get :moderation_flag, path: 'moderazione'
    end
    collection do
      get :large_map, path: 'dettaglio_mappa'
      #get :oportunities, path: 'opportunita'
    end

    resources :questions, only: [:show] do
      member do
        #moderazione centralizzata sul progetto
        #get :moderation_flag, path: 'moderazione'
      end
      resources :answers, only: [:create]
    end

    resources :proposals, path: 'proposte' do
      member do
        post :vote
        put :flag
        get :retire_form
        patch :retire
        put :unflag
        #moderazione centralizzata sul progetto
        #get :moderation_flag, path: 'moderazione'
      end
      collection do
        get :map, path: 'mappa'
        get :suggest
      end
    end

    resources :draft_versions, only: [:show] do
      get :go_to_version, on: :collection
      get :changes
      resources :annotations do
        get :search, on: :collection
        get :comments
        post :new_comment
      end
    end
  end

end

get 'legislation/processes/:id/json_data', action: :json_data, controller: 'legislation/processes'
