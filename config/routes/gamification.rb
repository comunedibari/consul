resources :gamifications, only: [:show,:index] , path: '/gamificazione' do
    member do
      get :json_data
      
    end
    collection do
      get :user
    end    
end
  
  get 'gamifications/:id/json_data', action: :json_data, controller: 'gamifications'