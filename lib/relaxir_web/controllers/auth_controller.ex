defmodule RelaxirWeb.AuthController do
  use RelaxirWeb, :controller
  plug Ueberauth
  alias Relaxir.Accounts
  alias RelaxirWeb.Authentication

  def request(conn, _params) do
    IO.inspect conn
  end

  def callback(%{assigns: %{ueberauth_auth: auth_data}} = conn, _params) do
    case Accounts.get_or_register(auth_data) do
      {:ok, account} ->
        conn
        |> Authentication.log_in(account)
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
