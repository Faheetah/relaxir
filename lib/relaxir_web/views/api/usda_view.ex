defmodule RelaxirWeb.Api.UsdaView do
  use RelaxirWeb, :view
  alias RelaxirWeb.Api.UsdaView

  def render("index.json", %{food: food}) do
    IO.inspect food
    render_many(food, UsdaView, "food.json")
  end

  def render("food.json", %{usda: food}) do
    %{fdc_id: food.fdc_id, description: food.description}
  end

  def render("show.json", %{food: food}) do
    render_one(food, UsdaView, "food_detail.json")
  end

  def render("food_detail.json", %{usda: food}) do
    food
  end
end
