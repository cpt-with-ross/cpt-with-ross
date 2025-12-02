Rails.application.routes.draw do
  resources :alternative_thoughts
  resources :abc_worksheets
  resources :stuck_points
  resources :impact_statements
  resources :traumas
  resources :models, only: %i[index show] do
    collection do
      post :refresh
    end
  end
  resources :chats do
    resources :messages, only: [:create]
  end
  resources :models, only: %i[index show] do
    collection do
      post :refresh
    end
  end
  devise_for :users
  root to: 'pages#home'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
