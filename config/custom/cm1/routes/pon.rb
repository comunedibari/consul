resources :pons, only: [:index, :show], path: 'enti'

  get '/pons', to: 'pons#index',  controller: 'pons'