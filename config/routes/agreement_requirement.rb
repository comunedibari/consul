


namespace :admin, path: 'amministrazione' do
  resources :agreement_requirements, only: [:show, :index], path: 'documenti_obbligatori' do
    resources :answers, only: [:create]
  end


  get 'agreement_requirements/:id/json_data', action: :json_data, controller: 'agreement_requirements'
end
