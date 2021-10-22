
# resources :agreements, only: [:index, :show], controller: :chances, path: 'opportunita', as: 'chances' do
#   collection do
#     get :large_map, path: 'dettaglio_mappa'
#   end  
# end

# resources :agreements, only: [:index, :show], controller: 'processes_proposals', path: 'proposte_e_progetti', as: 'processes_proposals' do
#   collection do
#     get :large_map, path: 'dettaglio_mappa'
#   end  
# end  

# resources :agreements, only: [:index, :show], controller: :subscriptions, path: 'sottoscrizioni', as: 'subscriptions' do
#   collection do
#     get :large_map, path: 'dettaglio_mappa'
#   end  
# end

namespace :collaboration, path: 'patti_di_collaborazione' do

  
  resources :agreements, only: [:index, :show], path: '' do

    resources :subscriptions, path: 'adesioni' do
    end

    member do
      get :debate , path: 'consultazioni'
      get :sgap , path: 'sgap'
      get :draft_publication, path: 'aggiornamenti'
      get :allegations, path: 'allegati'
      get :result_publication, path: 'risultati'
      get :proposals, path: 'proposte'
      get :moderation_flag, path: 'moderazione'
      put :flag
      put :unflag 
      get :json_data
      get :social_flag, path: 'social'

    end
    collection do
      get :large_map, path: 'dettaglio_mappa'
      #get :oportunities, path: 'opportunita'
    end

    resources :questions, only: [:show] do
      resources :answers, only: [:create]
    end


   


    resources :proposals, path: 'proposte' do
      member do
        post :vote
        put :flag
        get :retire_form
        patch :retire
        put :unflag
        get :moderation_flag, path: 'moderazione'        
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

get 'collaboration/agreements/:id/json_data', action: :json_data, controller: 'collaboration/agreements'
