# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :relaxir,
  ecto_repos: [Relaxir.Repo]

config :relaxir, :registration, enabled: false

# Configures the endpoint
config :relaxir, RelaxirWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "6lFP79ir6YXHSm71b8+XKI75KIKXcA/FgXPzWwMrEISUBlz9a09Xcb1T9FEW19jK",
  render_errors: [view: RelaxirWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Relaxir.PubSub,
  live_view: [signing_salt: "HNKcYMPI"]


# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

  # Invert
config :invert, Invert,
  tables: [
    {Relaxir.Usda.Food, :description, [:description, :fdc_id]},
    {Relaxir.Ingredients.Ingredient, :name, [:name, :id]},
    {Relaxir.Categories.Category, :name, [:name, :id]},
    {Relaxir.Recipes.Recipe, :title, [:title, :id]}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
