#get '/events', to: 'events#index' path: 'eventi'

resources :events, path: 'eventi' do
    member do
      post :vote
      put :flag
      put :unflag
      get :retire_form
      get :moderation_flag, path: 'moderazione'
      get :social_flag, path: 'social'
      get :share
      get :json_data
    end
    collection do
      get :map, path: 'mappa'
      get :suggest
      get :large_map, path: 'dettaglio_mappa'
    end
  end

  #get 'events/:id/json_data', action: :json_data, controller: 'events'