# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :relaxir,
  ecto_repos: [Relaxir.Repo]

# Configures the endpoint
config :relaxir, RelaxirWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "6lFP79ir6YXHSm71b8+XKI75KIKXcA/FgXPzWwMrEISUBlz9a09Xcb1T9FEW19jK",
  render_errors: [view: RelaxirWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Relaxir.PubSub,
  live_view: [signing_salt: "HNKcYMPI"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, []},
    identity: {
      Ueberauth.Strategy.Identity,
      [
        param_nesting: "user",
        request_path: "/register",
        callback_path: "/register",
        callback_methods: ["POST"]
      ]
    }
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

config :relaxir, RelaxirWeb.Authentication,
  issuer: "relaxir",
  secret_key: "PXqHaM2ZyRSldcH0roFOkRUHL/QM/ADXp1Zi9vtG8MX3kZjiUE/hl14Ej2E++H7A"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
