defmodule Relaxir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Relaxir.Repo,
      # Start the Telemetry supervisor
      RelaxirWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Relaxir.PubSub},
      # Start the Endpoint (http/https)
      RelaxirWeb.Endpoint,
      # Start a worker by calling: Relaxir.Worker.start_link(arg)
      # {Relaxir.Worker, arg}
      {Relaxir.Search,
       name: Relaxir.Search,
       repo: Relaxir.Repo,
       tables: [
         relaxir_ingredients_ingredient: [:name, :id],
         relaxir_categories_category: [:name, :id],
         relaxir_recipes_recipe: [:title, :id],
         relaxir_ingredients_food: [:description, :fdc_id]
       ]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Relaxir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RelaxirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
