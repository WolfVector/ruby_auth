Auth::Engine.routes.draw do
  root 'static_pages#home'
  get 'test_page', to: "static_pages#test_page"
  
  post "sign_up", to: "users#create"
  get "sign_up", to: "users#new"

  #Aplica resources urls para sólo para create, edit y new
  #param cambia :id por :confirmation_token
  resources :confirmations, only: [:create, :edit, :new], param: :confirmation_token
  resources :passwords, only: [:create, :edit, :new, :update], param: :password_reset_token

  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  get "login", to: "sessions#new"

  put "account", to: "users#update"
  get "account", to: "users#edit"
  delete "account", to: "users#destroy"
end
