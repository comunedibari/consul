

root 'welcome#services'
get '/welcome', to: 'welcome#welcome'
get '/welcome/style', action: :style, controller: 'welcome'