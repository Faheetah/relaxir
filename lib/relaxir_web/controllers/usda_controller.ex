defmodule RelaxirWeb.UsdaController do
  use RelaxirWeb, :controller

  alias Relaxir.Usda

  def index(conn, _params) do
    usda = Usda.list_food()
    render(conn, "index.html", usda: usda)
  end

  def show(conn, %{"id" => id}) do
    usda = Usda.get_food!(id)
    nutrients =
      usda.food_nutrients
      |> Enum.reduce(%{}, fn n, acc -> Map.put(acc, n.nutrient.name, "#{n.amount}#{String.downcase(n.nutrient.unit_name)}") end)

    render(conn, "show.html", usda: usda, nutrients: nutrients)
  end
end
