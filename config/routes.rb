Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines devise routes for user authentication
  devise_for :users
  # Defines the root path route ("/")
  root to: 'traumas#index'
  # Defines routes for traumas resource
  resources :traumas, only: %i[create edit update destroy] do
    resources :stuck_points, only: %i[index create edit update destroy] do
      resources :abc_worksheets, only: %i[index create edit update destroy]
      resources :alternative_thoughts, only: %i[index create edit update destroy]
    end
  end
end
