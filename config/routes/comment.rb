resources :comments, only: [:create, :show], shallow: true , path: 'commenti' do
  member do
    post :vote
    put :flag
    put :unflag
  end
end
