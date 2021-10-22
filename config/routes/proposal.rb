resources :proposals, path: Rails.application.config.route_proposals do
  member do
    post :vote
    post :vote_featured
    put :flag
    put :unflag
    get :retire_form
    get :share
    patch :retire
    get :moderation_flag, path: 'moderazione'
    get :social_flag, path: 'social'
    get :json_data
  end

  collection do
    get :map, path: 'mappa'
    get :suggest
    get :summary
    get :large_map, path: 'dettaglio_mappa'
  end
end

get 'proposals/:id/json_data', action: :json_data, controller: 'proposals'