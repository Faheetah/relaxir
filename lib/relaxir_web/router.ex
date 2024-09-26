defmodule RelaxirWeb.Router do
  use RelaxirWeb, :router

  import RelaxirWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :put_root_layout, html: {RelaxirWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :fetch_current_user
    plug :meta_defaults
  end

  @default_meta [
    %{property: "og:ttl", content: "600"},
    %{property: "og:type", content: "image"},
    %{property: "og:title", content: "Relax+Dine"},
    %{property: "og:description", content: "Fine dining and practical recipes."},
    %{property: "og:url", content: "https://www.relaxanddine.com"},
    %{property: "og:image", content: "/images/default-full.jpg"}
  ]

  def meta_defaults(conn, _opts) do
    assign(conn, :meta_attrs, @default_meta)
  end

  pipeline :live_browser do
    plug :put_root_layout, {RelaxirWeb.Layouts, :root}
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser]

    scope "/" do
      pipe_through [:require_authenticated_user, :require_admin]
      resources "/recipes", RecipeController, except: [:show, :index]

      resources "/grocerylists", GroceryListController
      delete "/grocerylists/:id/ingredient/:ingredient_id", GroceryListController, :remove_ingredient
      post "/grocerylists/:id/ingredient/:ingredient_id", GroceryListController, :add_ingredient

      resources "/inventorylists", InventoryListController
      delete "/inventorylists/:id/ingredient/:ingredient_id", InventoryListController, :remove_ingredient
      post "/inventorylists/:id/ingredient/:ingredient_id", InventoryListController, :add_ingredient

      post "/recipes/new", RecipeController, :new
      post "/recipes/:id/edit", RecipeController, :edit
      resources "/ingredients", IngredientController, except: [:show, :index]
      get "/ingredients/:ingredient_id/addToList", IngredientController, :select_list
      live_dashboard "/dashboard", metrics: RelaxirWeb.Telemetry


      scope "/", as: :recipe do
        pipe_through [:live_browser]
        live "/recipes/:id/upload", UploadLive, :new
      end
    end

    get "/", RecipeController, :index

    scope "/" do
      pipe_through [:live_browser]
      live "/search", SearchLive, :search
    end

    resources "/recipes", RecipeController, only: [:show, :index]
    get "/tools", ToolController, :index
    get "/tools/:name", ToolController, :show
    # this needs pagination
    # get "/usda", UsdaController, :index
    get "/usda/:id", UsdaController, :show
    get "/ingredients/all", IngredientController, :all
    resources "/ingredients", IngredientController, only: [:show, :index]
    get "/categories/all", CategoryController, :all
    resources "/categories", CategoryController, only: [:index]
    get "/categories/:name", CategoryController, :show
  end

  ## Authentication routes

  scope "/", RelaxirWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    get "/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    get "/login", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/profile", UserSettingsController, :profile
    get "/profile", UserSettingsController, :profile
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    delete "/logout", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end

  ## Authentication routes

  scope "/", RelaxirWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{RelaxirWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{RelaxirWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", RelaxirWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{RelaxirWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new

      live "/new/recipes", RecipeLive.Index, :index
      live "/new/recipes/:id", RecipeLive.Show, :show
      live "/new/recipes/new", RecipeLive.Index, :new
      live "/new/recipes/:id/edit", RecipeLive.Index, :edit
      live "/new/recipes/:id/show/edit", RecipeLive.Show, :edit
    end
  end
end
