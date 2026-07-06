Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Signed-in users land on the home dashboard; everyone else sees the login form.
  devise_scope :user do
    authenticated :user do
      root "home#index", as: :authenticated_root
    end
    unauthenticated :user do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end
  # Fallback so `root_path` resolves; home#index still requires authentication.
  root "home#index"

  get "profile" => "profiles#show", as: :profile
  get "profile/nutrition_goals/edit" => "user_settings#edit", as: :edit_nutrition_goals
  patch "profile/nutrition_goals" => "user_settings#update", as: :nutrition_goals
  post "profile/staple_recipes" => "user_staple_recipes#create", as: :staple_recipes
  delete "profile/staple_recipes/:id" => "user_staple_recipes#destroy", as: :staple_recipe

  resources :recipes, only: [ :show ]

  get "nutrition" => "nutrition#show", as: :nutrition
  get "nutrition/history" => "nutrition#history", as: :nutrition_history
  post "nutrition/log" => "nutrition#log", as: :nutrition_log
  delete "nutrition/clear" => "nutrition#clear_day", as: :nutrition_clear
  post "nutrition/entries/bulk" => "nutrition#bulk_update", as: :nutrition_bulk
  post "nutrition/sync" => "nutrition#sync", as: :nutrition_sync
  get "nutrition/entries/:id/edit" => "nutrition#edit_entry", as: :edit_nutrition_entry
  patch "nutrition/entries/:id" => "nutrition#update_entry"
  delete "nutrition/entries/:id" => "nutrition#destroy_entry", as: :nutrition_entry

  resources :home, only: [ :index ] do
    collection do
      get :recipe_analysis
      get :substitutions
      get :meal_planning
      post :analyze_recipe
      post :suggest_substitutions
      post :suggest_meal_plan
      post :meal_plan_prompt_preview
    end
  end
end
