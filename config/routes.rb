Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines devise routes for user authentication
  devise_for :users

  # 1. Dashboard: The persistent shell with blank center
  root 'dashboard#index'

  # 2. Main Hierarchy
  resources :index_events, shallow: true, only: %i[index new create edit update destroy] do
    resource :impact_statement, only: %i[show edit update]
    resources :stuck_points, only: %i[new create edit update destroy] do
      resources :abc_worksheets, only: %i[new create show edit update destroy]
      resources :alternative_thoughts, only: %i[new create show edit update destroy]
    end
  end
end
