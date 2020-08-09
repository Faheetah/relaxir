defmodule RelaxirWeb.Api.IngredientView do
  use RelaxirWeb, :view
  alias RelaxirWeb.Api.IngredientView

  def render("index.json", %{ingredients: ingredients}) do
    render_many(ingredients, IngredientView, "ingredient.json")
  end

  def render("show.json", %{ingredient: ingredient}) do
    render_one(ingredient, IngredientView, "ingredient.json")
  end

  def render("ingredient.json", %{ingredient: ingredient}) do
    %{id: ingredient.id, name: ingredient.name}
  end
end
