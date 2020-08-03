defmodule RelaxirWeb.Router do
  use RelaxirWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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
    pipe_through [:browser, :guardian, :browser_auth]

    resources "/recipes", RecipeController
    resources "/users", UserController
    resources "/profile", ProfileController, only: [:show], singleton: true
    
    delete "/logout", SessionController, :delete
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser]

    get "/", PageController, :index
    resources "/recipes", RecipeController, only: [:show, :index]
    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create

    get "/login", SessionController, :new
    post "/login", SessionController, :create
  end

  scope "/auth", RelaxirWeb do
    pipe_through [:browser, :guardian]

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/api", RelaxirWeb do
    pipe_through :api

    resources "/ingredients", IngredientController
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: RelaxirWeb.Telemetry
    end
  end
end
