defmodule RelaxirWeb.SearchController do
  use RelaxirWeb, :controller

  def search_for(module, name, terms) do
    case Relaxir.Search.get(module, name, terms) do
      {:ok, results} -> results
      {:error, :not_found} -> [{"no results found", 0}]
    end
    |> Enum.map(fn {i, _} -> i end)
  end

  def search(conn, %{"terms" => terms}) do
    recipes = search_for(Relaxir.Recipes.Recipe, :name, terms)
    |> Enum.take(20)

    ingredients = search_for(Relaxir.Ingredients.Ingredient, :name, terms)
    |> Enum.take(20)

    food = search_for(Relaxir.Ingredients.Food, :description, terms)
    |> Enum.take(20)

    render(conn, "search.html", results: [Recipes: recipes, Ingredients: ingredients, USDA: food])
  end

  def search(conn, _params) do
    render(conn, "search.html", results: [])
  end
end
