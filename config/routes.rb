Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Application health check at /health returning {"status":"ok"} — for load balancers,
  # monitoring systems, and deployment infrastructure. No authentication, no DB access.
  get "health" => "health#show"

  # Versioned API namespace: unauthenticated, JSON-only, no DB access. Health check
  # mirrors the root /health semantics; /api/v1/endpoints self-describes the namespace
  # by listing every route under /api/v1 (derived from the live route table).
  namespace :api do
    namespace :v1 do
      get "health" => "health#show"
      get "endpoints" => "endpoints#index"
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
