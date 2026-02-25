Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # ActionCable
  mount ActionCable.server => "/cable"

  # API v1
  namespace :api do
    namespace :v1 do
      # Auth
      post "auth/register", to: "auth#register"
      post "auth/login",    to: "auth#login"
      get  "auth/me",       to: "auth#me"

      # Credit Applications
      resources :credit_applications, only: [ :index, :show, :create ] do
        collection do
          get :countries
          get :statuses
        end
        member do
          patch :update_status
        end
      end

      # Webhooks (sin autenticación JWT, con secret propio)
      post "webhooks/bank_update", to: "webhooks#bank_update"
    end
  end
end
