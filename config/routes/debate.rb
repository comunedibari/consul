resources :debates, path: Rails.application.config.route_debates do
  member do
    post :vote
    put :flag
    put :unflag
    put :mark_featured
    put :unmark_featured
    get :share
    get :moderation_flag, path: 'moderazione'
    get :json_data
  end

  collection do
    get :map, path: 'mappa'
    get :suggest
    get :large_map, path: 'dettaglio_mappa'
  end
end

get 'debates/:id/json_data', action: :json_data, controller: 'debates'