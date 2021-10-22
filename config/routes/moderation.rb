namespace :moderation, path: 'moderazione' do
  root to: "dashboard#index"

  resources :users, only: :index, path: 'utenti' do
    member do
      put :hide
      put :hide_in_moderation_screen
    end
  end

  resources :debates, only: :index, path: 'forum' do
    put :hide, on: :member
    put :moderate, on: :collection
  end

  resources :proposals, only: :index, path: Rails.application.config.route_proposals do
    put :hide, on: :member
    put :moderate, on: :collection
  end

=begin
  resources :crowdfundings, only: :index, path: Rails.application.config.route_crowdfundings do
    put :hide, on: :member
    put :moderate, on: :collection
  end
=end


  resources :comments, only: :index, path: 'commenti' do
    put :hide, on: :member
    put :moderate, on: :collection
  end

  resources :events, only: :index, path: 'eventi' do
    put :hide, on: :member
    put :moderate, on: :collection
  end

  resources :reportings, only: :index, path: 'segnalazioni' do
    put :hide, on: :member
    put :moderate, on: :collection
  end

  resources :processes,  controller: "processes", path: 'proposte_e_iniziative' do
    put :hide, on: :member
    put :moderate, on: :collection
  end

=begin
  resources :agreements,  controller: "agreements", path: 'patti_di_collaborazione' do
    put :hide, on: :member
    put :moderate, on: :collection
  end
=end

  namespace :legislation, path: 'proposte' do
    resources :proposals, path: 'proposte_utente' do
      put :hide, on: :member
      put :moderate, on: :collection
    end
  end
end
