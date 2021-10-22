resources :polls, only: [:show, :index] , path: 'consultazioni' do
  member do
    #get :stats, path: 'statistiche'
    get :results, path: 'risultati'
    post :confirm, path: 'confirm'
    get :download_result
    get :moderation_flag, path: 'moderazione'
    get :social_flag, path: 'social'

  end

  resources :questions, controller: 'polls/questions', shallow: true , path: 'quesiti' do
    post :answer, on: :member, path: 'quesito'

  end
end
