defmodule RelaxirWeb.SessionController do
  use RelaxirWeb, :controller
  alias Relaxir.Users
  alias RelaxirWeb.Authentication

  def new(conn, params) do
    if Authentication.get_current_user(conn) do
      case Map.fetch(params, "redirected_from") do
        {:ok, path} -> redirect(conn, to: path)
        _ -> redirect(conn, to: Routes.profile_path(conn, :show))
      end
    else
      render(
        conn,
        :new,
        changeset: Users.change_user(),
        action: Routes.session_path(
          conn,
          :create,
          redirected_from: Map.get(params, "redirected_from")
        )
      )
    end
  end

  def create(conn, params = %{"user" => %{"email" => email, "password" => password}}) do
    case email
         |> String.downcase()
         |> Users.get_by_email()
         |> Authentication.authenticate(password) do
      {:ok, user} ->
        conn = Authentication.log_in(conn, user)
        case Map.fetch(params, "redirected_from") do
          {:ok, path} when path != "" -> redirect(conn, to: path)
          _ -> redirect(conn, to: Routes.profile_path(conn, :show))
        end

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
