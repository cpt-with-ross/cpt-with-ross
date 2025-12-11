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

  # Shared routes for exportable resources (PDF export and email sharing)
  concern :exportable do
    member do
      get :export
      post :share
    end
  end

  resources :index_events, shallow: true, only: %i[new create show edit update destroy] do
    resource :baseline, only: %i[show edit update], concerns: :exportable
    resources :stuck_points, only: %i[new create show edit update destroy], concerns: :exportable do
      resources :abc_worksheets, only: %i[new create show edit update destroy], concerns: :exportable
      resources :alternative_thoughts, only: %i[new create show edit update destroy], concerns: :exportable
    end
  end
end
