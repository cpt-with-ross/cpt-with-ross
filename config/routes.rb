Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  devise_for :users, skip: %i[registrations passwords], controllers: {
    sessions: 'users/sessions'
  }

  root 'dashboard#index'

  resources :chats, only: [:create] do
    member do
      delete :clear
    end
    resources :messages, only: [:create]
  end

  resources :index_events, shallow: true, only: %i[new create show edit update destroy] do
    resource :baseline, only: %i[show edit update]
    resources :stuck_points, only: %i[new create show edit update destroy] do
      resources :abc_worksheets, only: %i[new create show edit update destroy]
      resources :alternative_thoughts, only: %i[new create show edit update destroy]
    end
  end
end
