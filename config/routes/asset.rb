resources :assets, path: Rails.application.config.route_assets do
  member do
    post :vote
    post :vote_featured
    put :flag
    put :unflag
    get :retire_form
    get :share
    patch :retire
    get :moderation_flag, path: 'moderazione'
    get :json_data
    get :social_flag, path: 'social'
    #get :add_reservation, path: 'prenotazione'

  end

  collection do
    get :map, path: 'mappa'
    get :suggest
    get :summary
    get :large_map, path: 'dettaglio_mappa'
  end

  namespace :booking_manager, path: '' do

    resources :moderable_bookings, controller: 'moderable_bookings', path: '/prenotazioni' do
      member do
        get :retire_form
        patch :retire
        get :social_flag, path: 'social'
      end
    end
  end

end


get 'assets/:id/json_data', action: :json_data, controller: 'assets'
