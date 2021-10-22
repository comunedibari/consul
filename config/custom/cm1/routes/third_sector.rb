namespace :admin , path: 'amministrazione' do

  resources :sectors, path: 'terzo_settore' do
    member do
      get :share
      put :relation
      put :rem_relation
    end
    collection do
      get :downloadxlsx, path: 'download_template'
      get :map, path: 'mappa'
      get :large_map, path: 'dettaglio_mappa'
    end
  end

end

resources :sectors, path: 'settori' do
  collection do
    get :map, path: 'mappa'
    get :large_map, path: 'dettaglio_mappa'
  end
  member do
    get :json_data
    get :share
    put :delete
    get :clean_st
  end
end

resources :st_sectors, path: 'settore' do
  member do
    get :share
    put :delete
  end
=begin
  collection do
    get :map, path: 'mappa'
    get :large_map, path: 'dettaglio_mappa'
  end
  member do
    get :json_data
  end
=end
end

resources :sector_types, only: [:index, :show], path: 'terzo_settore'  do
  member do
    get :share
    get :proposals
  end
  collection do
    get :map
    get :suggest
    get :summary
    get :large_map
  end
end





get 'sector_types/:id/json_data', action: :json_data, controller: 'sector_types'
get 'sectors/:id/json_data', action: :json_data, controller: 'sectors'

#post '/terzo_settore/upload', action: :create, controller: 'sectors'
