defmodule RelaxirWeb.Authentication.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :relaxir,
    error_handler: RelaxirWeb.Authentication.ErrorHandler,
    module: RelaxirWeb.Authentication

  plug Guardian.Plug.VerifySession, claims: %{"type" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
