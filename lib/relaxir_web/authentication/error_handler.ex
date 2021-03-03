defmodule RelaxirWeb.Authentication.ErrorHandler do
  use RelaxirWeb, :controller

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, _opts) do
    error_message =
      case reason do
        :token_expired -> "Your session has expired."
        _ -> "An unknown error occurred, please log back in. #{type}/#{reason}"
      end

    conn
    |> RelaxirWeb.Authentication.log_out()
    |> put_flash(:error, "Authentication error. Please log back in. #{error_message}")
    |> redirect(to: Routes.session_path(conn, :new, redirected_from: conn.request_path))
  end
end
