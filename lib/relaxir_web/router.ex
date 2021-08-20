defmodule RelaxirWeb.Router do
  import Phoenix.LiveDashboard.Router

  use RelaxirWeb, :router

  import RelaxirWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'"}
    plug :fetch_current_user
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser]

    scope "/" do
      pipe_through [:require_authenticated_user, :require_admin]
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

    get "/search", SearchController, :new
    post "/search", SearchController, :search
    resources "/recipes", RecipeController, only: [:show, :index]
    get "/tools", ToolController, :index
    get "/tools/:name", ToolController, :show
    resources "/ingredients", IngredientController, only: [:show, :index]
    resources "/categories", CategoryController, only: [:show, :index]
  end

  ## Authentication routes

  scope "/", RelaxirWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end
end
