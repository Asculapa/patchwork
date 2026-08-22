Rails.application.routes.draw do
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]
  resource :settings, only: %i[show update]
  resources :push_subscriptions, only: %i[create destroy], constraints: { id: %r{.+} }

  resources :entries, only: %i[index show] do
    collection { post :mark_all_read }
    scope module: :entries do
      resource :star, only: %i[create destroy]
      resource :read, only: %i[create destroy]
    end
  end

  resources :subscriptions, except: :show do
    member { post :refresh }
  end
  resources :groups, except: %i[show new]
  resource :opml, only: %i[show new create], controller: "opml"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "entries#index"
end
