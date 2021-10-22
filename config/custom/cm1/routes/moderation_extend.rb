namespace :moderation, path: 'moderazione' do

  resources :sectors, path: 'associazione_terzo_settore' do
    member do
      get :outcome
      patch :actions
    end
  end
end

