Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "nodes#index"

  get "/common_ancestor", to: "nodes#common_ancestor"

  resources :nodes, only: [] do
    collection do
      get :common_ancestor
    end
  end

end
