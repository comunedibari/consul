require 'sidekiq/web'

Rails.application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  # mount Sidekiq::Web => "/sidekiq"

  if Rails.env.development? || Rails.env.staging?
    get '/sandbox' => 'sandbox#index'
    get '/sandbox/*template' => 'sandbox#show'
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "/payment_callback/wsdl", to: 'payment_callback#wsdl'
  post "/payment_callback/wsdl", to: 'payment_callback#paymentResponse'

  draw_custom :welcome
  draw_custom :debate
  draw :admin
  draw :annotation
  draw :budget
  draw :comment
  draw :community
  #draw :debate
  draw :devise
  draw :direct_upload
  draw :document
  draw :graphql
  draw :guide
  draw :legislation
  #draw :management
  draw :moderation
  draw :notification
  draw :officing
  draw :poll
  draw :proposal
  draw :crowdfunding
  draw :related_content
  draw :tag
  draw :user
  draw :valuation
  draw :verification
  draw :geo
  #draw :agreement_requirement
  draw :asset
  #draw :reservation
  draw :collaboration
  draw :gamification
  draw_custom :account
  draw_custom :admin_extend
  draw_custom :reporting
  draw_custom :third_sector
  draw_custom :events
  draw_custom :user_tag
  draw_custom :pon
  draw_custom :opendata
  draw_custom :moderation_extend



  resources :messages do
    collection do
      get :prova
    end
  end



  get '/consul.json', to: "installation#details"

  resources :stats, only: [:index]
  resources :images, only: [:destroy]
  resources :documents, only: [:destroy]
  resources :follows, only: [:create, :destroy],  :path => 'segui'

  # More info pages
  get 'aiuto',             to: 'pages#show', id: 'help/index',             as: 'help'
  get 'aiuto/come_usarlo',  to: 'pages#show', id: 'help/how_to_use/index',  as: 'how_to_use'
  get 'aiuto/domande',         to: 'pages#show', id: 'help/faq/index',         as: 'faq'


  get "/admin" => redirect("/amministrazione")
  get "/moderation" => redirect("/moderazione")

  # Static pages
  get '/blog' => redirect("http://blog.consul/")
  resources :pages, path: '/', only: [:show]

  #get '*unmatched_route', to: 'application#raise_not_found'



end
