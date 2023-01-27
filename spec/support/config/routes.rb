Rails.application.routes.draw do
  namespace :guards do
    resources :examples, only: %i[index show]
  end
end
