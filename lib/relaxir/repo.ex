defmodule Relaxir.Repo do
  use Ecto.Repo,
    otp_app: :relaxir,
    adapter: Ecto.Adapters.Postgres
end
