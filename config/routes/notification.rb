resources :notifications, only: [:index, :show], path: 'notifiche' do
  put :mark_as_read, on: :member
  put :mark_all_as_read, on: :collection
  put :mark_as_unread, on: :member
  get :read, on: :collection
end

resources :crowdfunding_notifications, only: [:new, :create, :show] , path: 'notifiche_' + Rails.application.config.route_crowdfundings
resources :proposal_notifications, only: [:new, :create, :show] , path: 'notifiche_' + Rails.application.config.route_proposals
resources :reporting_notifications, only: [:new, :create, :show], path: 'notifiche_segnalazioni'

namespace :collaboration, path: 'collaboration' do
  resources :agreement_notifications, only: [:new, :create, :show], path: 'notifiche_patti'
end
