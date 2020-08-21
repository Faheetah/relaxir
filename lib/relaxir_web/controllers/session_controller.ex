defmodule RelaxirWeb.SessionController do
  use RelaxirWeb, :controller
  alias Relaxir.Users
  alias RelaxirWeb.Authentication

  def new(conn, _params) do
    if Authentication.get_current_user(conn) do
      redirect(conn, to: Routes.profile_path(conn, :show))
    else
      render(
        conn,
        :new,
        changeset: Users.change_user(),
        action: Routes.session_path(conn, :create)
      )
    end
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case email
         |> Users.get_by_email()
         |> Authentication.authenticate(password) do
      {:ok, user} ->
        conn
        |> Authentication.log_in(user)
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
