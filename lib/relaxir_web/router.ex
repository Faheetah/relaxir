defmodule RelaxirWeb.Router do
  import Phoenix.LiveDashboard.Router
  import RelaxirWeb.Authentication, only: [load_current_user: 2, require_admin: 2]

  use RelaxirWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :guardian do
    plug RelaxirWeb.Authentication.Pipeline
  end

  pipeline :browser_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser, :guardian]

    scope "/" do
      pipe_through [:browser_auth]

      resources "/profile", ProfileController, only: [:show], singleton: true

      delete "/logout", SessionController, :delete
    end

    scope "/" do
      pipe_through [:browser_auth, :require_admin]
      resources "/recipes", RecipeController, except: [:show, :index]

      resources "/recipelists", RecipeListController
      delete "/recipelists/:id/recipe/:recipe_id", RecipeListController, :remove_recipe
      get "/recipes/:recipe_id/addToList", RecipeListController, :select_list
      post "/recipelists/:id/recipe/:recipe_id", RecipeListController, :add_recipe

      resources "/grocerylists", GroceryListController
      delete "/grocerylists/:id/ingredient/:ingredient_id", GroceryListController, :remove_ingredient
      post "/grocerylists/:id/ingredient/:ingredient_id", GroceryListController, :add_ingredient

      resources "/inventorylists", InventoryListController
      delete "/inventorylists/:id/ingredient/:ingredient_id", InventoryListController, :remove_ingredient
      post "/inventorylists/:id/ingredient/:ingredient_id", InventoryListController, :add_ingredient

      post "/recipes/new", RecipeController, :new
      post "/recipes/:id/edit", RecipeController, :edit
      post "/recipes/confirm", RecipeController, :confirm_new
      put "/recipes/:id/confirm", RecipeController, :confirm_update
      post "/recipes/:id/confirm", RecipeController, :confirm_update
      resources "/ingredients", IngredientController, except: [:show, :index]
      get "/ingredients/:ingredient_id/addToList", IngredientController, :select_list
      resources "/categories", CategoryController, except: [:show, :index]
      live_dashboard "/dashboard", metrics: RelaxirWeb.Telemetry
    end

    get "/", RecipeController, :index
    # get "/register", RegistrationController, :new
    # post "/register", RegistrationController, :create

    get "/login", SessionController, :new
    post "/login", SessionController, :create

    get "/search", SearchController, :search
    post "/search", SearchController, :search
    resources "/recipes", RecipeController, only: [:show, :index]
    get "/tools", ToolController, :index
    get "/tools/:name", ToolController, :show
    resources "/ingredients", IngredientController, only: [:show, :index]
    resources "/categories", CategoryController, only: [:show, :index]
  end

  scope "/auth", RelaxirWeb do
    pipe_through [:browser, :guardian]

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/api", RelaxirWeb.Api do
    pipe_through :api

    resources "/ingredients", IngredientController, only: [:show, :index]
    resources "/food", UsdaController, [:show, :index]
  end
end
