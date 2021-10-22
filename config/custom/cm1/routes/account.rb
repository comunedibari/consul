resource :account, controller: "account", only: [:show, :update, :delete, :preferences], path: 'profilo' do
  get :erase, on: :collection
  get :preferences, path: 'preferenze'
  post :setPrivacy 
end
