defmodule RelaxirWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Caching Metrics
      summary("search.items.relaxir_recipes_recipe_title.total", description: "Recipes"),
      summary("search.items.relaxir_categories_category_name.total", description: "Categories"),
      summary("search.items.relaxir_ingredients_ingredient_name.total", description: "Ingredients"),
      summary("search.items.relaxir_ingredients_food_description.total", description: "USDA Food"),
      summary("search.query.total_time", unit: {:native, :nanosecond}),

      # Database Metrics
      summary("relaxir.repo.query.total_time", unit: {:native, :millisecond}),
      summary("relaxir.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("relaxir.repo.query.query_time", unit: {:native, :millisecond}),
      summary("relaxir.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("relaxir.repo.query.idle_time", unit: {:native, :millisecond}),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    Relaxir.Application.get_cache_tables()
    |> Enum.map(fn t -> {Invert, :get_count, Tuple.to_list(t)} end)
  end
end
