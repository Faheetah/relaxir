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
      resources "/ingredients", IngredientController
      live_dashboard "/dashboard", metrics: RelaxirWeb.Telemetry
    end

    get "/", RecipeController, :index
    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create

    get "/login", SessionController, :new
    post "/login", SessionController, :create

    resources "/recipes", RecipeController, only: [:show, :index]
  end

  scope "/auth", RelaxirWeb do
    pipe_through [:browser, :guardian]

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/api", RelaxirWeb.Api do
    pipe_through :api

    resources "/ingredients", IngredientController, only: [:show, :index]
  end
end
