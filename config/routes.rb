Rails.application.routes.draw do

  root "home#index"

  resources :gists

  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/sessions", to: "sessions#destroy"
end
