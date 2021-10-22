if  Rails.application.config.sign_up_service

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    confirmations: 'users/confirmations',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    patch '/user/confirmation', to: 'users/confirmations#update', as: :update_user_confirmation
    get '/user/registrations/check_username', to: 'users/registrations#check_username'
    get 'users/sign_up/success', to: 'users/registrations#success'
    get 'users/registrations/delete_form', to: 'users/registrations#delete_form', path: 'utenti/registrazione/cancella'
    delete 'users/registrations', to: 'users/registrations#delete', path: 'utenti/registrazione/elimina'
    get :finish_signup, to: 'users/registrations#finish_signup' 
    patch :do_finish_signup, to: 'users/registrations#do_finish_signup'
  end
else
  devise_for :users, skip: [:confirmations], controllers: {
    registrations: 'users/sessions', # disable sign_up
    sessions: 'users/sessions',
    confirmations: 'users/confirmations',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    get "/login/admin" => "devise/sessions#login"
    get "/sign_up" => "devise/sessions#new"
    get 'users/registrations/delete_form', to: 'users/registrations#delete_form', path: 'utenti/registrazione/cancella'
    delete 'users/registrations', to: 'users/registrations#delete'
  end

end


devise_for :organizations, class_name: 'User',
           controllers: {
             registrations: 'organizations/registrations',
             sessions: 'devise/sessions',
           },
           skip: [:omniauth_callbacks]

devise_scope :organization do
  get 'organizations/sign_up/success', to: 'organizations/registrations#success'
end
