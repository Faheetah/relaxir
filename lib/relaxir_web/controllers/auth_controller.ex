defmodule RelaxirWeb.AuthController do
  use RelaxirWeb, :controller
  plug Ueberauth
  alias Relaxir.Users
  alias RelaxirWeb.Authentication

  def request(conn, _params) do
    conn
  end

  def callback(%{assigns: %{ueberauth_auth: auth_data}} = conn, _params) do
    case Users.get_or_register(auth_data) do
      {:ok, user} ->
        conn
        |> Authentication.log_in(user)
        |> redirect(to: Routes.profile_path(conn, :show))

      {:error, _error_changeset} ->
        conn
        |> put_flash(:error, "Authentication failed.")
        |> redirect(to: Routes.registration_path(conn, :new))
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed.")
    |> redirect(to: Routes.registration_path(conn, :new))
  end
end
