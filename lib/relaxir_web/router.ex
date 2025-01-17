defmodule RelaxirWeb.Router do
  use RelaxirWeb, :router

  import RelaxirWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :put_root_layout, html: {RelaxirWeb.Layouts, :root}
    plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self' data:"}
    plug :protect_from_forgery
    plug :fetch_current_user
    plug :meta_defaults
  end

  @doc """
  Assign default meta for OG use in root layout. Updating these in handle_params allows updating
  the meta that shows on social media. When redirecting away (i.e. deleting), ensure a full
  navigate happens so the meta is updated. It's not possible to dynamically update the root
  layout otherwise. This does incur a bit of a slower navigate, unfortunately.
  """
  def meta_defaults(conn, _opts) do
    assign(conn, :meta_attrs, %{})
  end

  pipeline :live_browser do
    plug :put_root_layout, {RelaxirWeb.Layouts, :root}
  end

  # Use authentication routes

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

  # Protected routes

  scope "/", RelaxirWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{RelaxirWeb.UserAuth, :ensure_authenticated}] do
      live "/profile", UserSettingsLive, :edit
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      delete "/users/log_out", UserSessionController, :delete
    end

    scope "/" do
      pipe_through [:require_admin]
      live_dashboard "/dashboard", metrics: RelaxirWeb.Telemetry
    end
  end

  # Public routes

  scope "/", RelaxirWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{RelaxirWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new

      live "/", RecipeLive.Index, :index
      live "/recipes", RecipeLive.Index, :index
      live "/recipes/:id", RecipeLive.Show, :show
      live "/new/recipes/new", RecipeLive.Index, :new
      live "/new/recipes/:id/edit", RecipeLive.Index, :edit
      live "/recipes/:id/show/edit", RecipeLive.Show, :edit

      live "/categories", CategoryLive.Index, :index
      live "/categories/:name", CategoryLive.Show, :show

      live "/search", SearchLive, :search

      live "/tools", ToolLive.Index, :index
      live "/tools/:name", ToolLive.Show, :show

      scope "/", as: :recipe do
        live "/recipes/:id/upload", UploadLive, :new
      end
    end
  end
end
