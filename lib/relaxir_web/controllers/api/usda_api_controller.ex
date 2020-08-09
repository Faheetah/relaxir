defmodule RelaxirWeb.Api.UsdaController do
  use RelaxirWeb, :controller

  alias Relaxir.Usda

  action_fallback RelaxirWeb.FallbackController

  def index(conn, _params) do
    food = Usda.list_food()
    render(conn, "index.json", food: food)
  end

  def show(conn, %{"id" => id}) do
    food = Usda.get_food!(id)
    render(conn, "show.json", food: food)
  end
end

