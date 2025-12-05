Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  devise_for :users

  root 'dashboard#index'

  resources :index_events, shallow: true, only: %i[index new create edit update destroy] do
    resource :impact_statement, only: %i[show edit update]
    resources :stuck_points, only: %i[new create edit update destroy] do
      resources :abc_worksheets, only: %i[new create show edit update destroy]
      resources :alternative_thoughts, only: %i[new create show edit update destroy]
    end
  end
end
