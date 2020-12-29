defmodule RelaxirWeb.Authentication do
  @moduledoc """
  Implementation module for Guardian and functions for authentication.
  """
  use Guardian, otp_app: :relaxir
  alias Relaxir.{Users, Users.User}
  import Plug.Conn

  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Users.get_user(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def load_current_user(conn, _) do
    conn
    |> assign(:current_user, Guardian.Plug.current_resource(conn))
  end

  def require_admin(conn, _) do
    case get_current_user(conn) do
      %Users.User{is_admin: true} ->
        conn

      _ ->
        RelaxirWeb.Authentication.ErrorHandler.auth_error(
          conn,
          {:requires_admin, :requires_admin},
          %{}
        )
    end
  end

  def get_current_user(conn) do
    __MODULE__.Plug.current_resource(conn)
  end

  def log_in(conn, user) do
    conn
    |> __MODULE__.Plug.sign_in(user, %{}, ttl: Application.get_env(:relaxir, __MODULE__)[:ttl])
  end

  def log_out(conn) do
    __MODULE__.Plug.sign_out(conn)
  end

  def authenticate(%User{} = user, password) do
    authenticate(
      user,
      password,
      Argon2.verify_pass(password, user.encrypted_password)
    )
  end

  def authenticate(nil, password) do
    authenticate(nil, password, Argon2.no_user_verify())
  end

  defp authenticate(user, _password, true) do
    {:ok, user}
  end

  defp authenticate(_user, _password, false) do
    {:error, :invalid_credentials}
  end
end
