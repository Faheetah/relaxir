defmodule Relaxir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @cache_tables [
    {Relaxir.Ingredients.Food, :description, [:description, :fdc_id]},
    {Relaxir.Ingredients.Ingredient, :name, [:name, :id]},
    {Relaxir.Categories.Category, :name, [:name, :id]},
    {Relaxir.Recipes.Recipe, :title, [:title, :id]}
  ]

  def get_cache_tables(), do: @cache_tables

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Relaxir.Repo,
      {Relaxir.Search.Cache, @cache_tables},
      {Relaxir.Search, tables: @cache_tables},
      {Relaxir.Search.Hydrator, repo: Relaxir.Repo, tables: @cache_tables},
      # Start the Telemetry supervisor
      RelaxirWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Relaxir.PubSub},
      # Start the Endpoint (http/https)
      RelaxirWeb.Endpoint
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
