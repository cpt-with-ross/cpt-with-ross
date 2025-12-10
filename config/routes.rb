Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Letter opener web interface for viewing emails in development
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

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
    resource :baseline, only: %i[show edit update] do
      get :summary, on: :member
      post :email, on: :member
    end
    resources :stuck_points, only: %i[new create show edit update destroy] do
      member do
        get :pdf
        post :email
      end
      resources :abc_worksheets, only: %i[new create show edit update destroy] do
        member do
          get :pdf
          post :email
        end
      end
      resources :alternative_thoughts, only: %i[new create show edit update destroy] do
        member do
          get :pdf
          post :email
        end
      end
    end
  end
end
