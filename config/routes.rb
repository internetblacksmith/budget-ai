Rails.application.routes.draw do
  resources :imports, only: [ :index ] do
    collection do
      post :import_emma
      get :check_import_status
      get :list_spreadsheets
      get :list_spreadsheet_sheets
      delete :reset_database
    end
  end

  resources :transactions do
    collection do
      post :bulk_update
    end
  end

  resources :insights, only: [ :index ] do
    collection do
      get :spending_analysis
      get :budget_suggestions
      post :categorize_transactions
      get :explain_pattern
      get :stream
    end
  end

  resources :budgets, only: %i[index create update destroy]

  resources :chat, only: %i[index create] do
    member { post :retry }
    collection { delete :clear }
  end

  get "google_auth/authorize", to: "google_auth#authorize", as: :google_auth_authorize
  get "google_auth/callback", to: "google_auth#callback", as: :google_auth_callback
  delete "google_auth/disconnect", to: "google_auth#disconnect", as: :google_auth_disconnect

  get "dashboard", to: "dashboard#index", as: :dashboard
  root "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
