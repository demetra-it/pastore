Rails.application.routes.draw do
  namespace :guards do
    resources :examples, only: %i[index show] do
      get :test_permit_role, on: :collection
      get :test_unpermitted_role, on: :collection
      get :test_denied_role, on: :collection
      get :test_authorized_with_permitted, on: :collection
      get :test_authorized_with_denied, on: :collection
      get :test_authorized_with_method, on: :collection
      get :test_authorization_priority, on: :collection
      get :test_authorization_priority2, on: :collection
      get :test_cumulative_permit_role, on: :collection
      get :test_cumulative_deny_role, on: :collection
    end
  end
end
