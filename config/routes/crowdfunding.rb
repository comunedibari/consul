resources :crowdfundings, path: Rails.application.config.route_crowdfundings do
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
      get :payment_outcome # path di ritorno dal portale pagamento
    end

    collection do
      get :map, path: 'mappa'
      get :suggest
      get :summary
      get :large_map, path: 'dettaglio_mappa'
    end

  resources :user_investments, only: [:create,:new, :show] , path: '/investimenti' do
    member do
      get :share
    end
  end


end

  get 'crowdfundings/:id/json_data', action: :json_data, controller: 'crowdfundings'
