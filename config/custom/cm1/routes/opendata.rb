
resources :opendatas, only: [:index], path: "OpenData" do
    get :download_csv, on: :collection, path: "DownloadCSV"
  end