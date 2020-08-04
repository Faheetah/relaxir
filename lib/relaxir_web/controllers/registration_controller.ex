defmodule RelaxirWeb.RegistrationController do
  use RelaxirWeb, :controller

  plug(Ueberauth)

  alias Relaxir.Users
  alias RelaxirWeb.Authentication

  def new(conn, _) do
    if Authentication.get_current_user(conn) do
      redirect(conn, to: Routes.recipe_path(conn, :index))
    else
      render(
        conn,
        :new,
        changeset: Users.change_user(),
        action: Routes.registration_path(conn, :create)
      )
    end
  end

  def create(%{assigns: %{ueberauth_auth: auth_params}} = conn, _params) do
    case Users.register(auth_params) do
      {:ok, user} ->
        conn
        |> Authentication.log_in(user)
        |> redirect(to: Routes.recipe_path(conn, :index))
      
      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          action: Routes.registration_path(conn, :create)
        )
    end
  end
end
