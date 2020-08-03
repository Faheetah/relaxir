defmodule RelaxirWeb.SessionController do
  use RelaxirWeb, :controller
  alias Relaxir.Accounts
  alias RelaxirWeb.Authentication

  def new(conn, _params) do
    if Authentication.get_current_account(conn) do
      redirect(conn, to: Routes.profile_path(conn, :show))
    else
      render(
        conn, 
        :new, 
        changeset: Accounts.change_account(),
        action: Routes.session_path(conn, :create)
      )
    end
  end

  def create(conn, %{"account" => %{"email" => email, "password" => password}}) do
    case email
         |> Accounts.get_by_email()
         |> Authentication.authenticate(password) do
      {:ok, account} ->
        conn
        |> Authentication.log_in(account)
        |> redirect(to: Routes.profile_path(conn, :show))

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Incorrect email/password combo")
        |> new(%{})
    end
  end

  def delete(conn, _params) do
    conn
    |> Authentication.log_out()
    |> redirect(to: Routes.session_path(conn, :new))
  end
end
