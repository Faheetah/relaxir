defmodule RelaxirWeb.SearchController do
  use RelaxirWeb, :controller

  alias Relaxir.Search

  @default_checkboxes %{
    recipes: true,
    categories: true,
    ingredients: true,
    usda: false
  }

  # default search page
  def new(conn, params) when map_size(params) == 0 do
    current_user = RelaxirWeb.Authentication.get_current_user(conn)
    render(conn, "search.html", current_user: current_user, count: :na, checkboxes: @default_checkboxes, results: [])
  end

  # search results
  def search(conn, params) do
    terms = params["terms"]
    current_user = RelaxirWeb.Authentication.get_current_user(conn)

    checkboxes = %{
      recipes: Map.get(params, "recipes", false) == "true",
      categories: Map.get(params, "categories", false) == "true",
      ingredients: Map.get(params, "ingredients", false) == "true",
      usda: Map.get(params, "usda", false) == "true"
    }

    recipes =
      case checkboxes.recipes do
        true -> Search.search_for(Relaxir.Recipes.Recipe, :title, terms)
        _ -> []
      end

    categories =
      case checkboxes.categories do
        true -> Search.search_for(Relaxir.Categories.Category, :name, terms)
        _ -> []
      end

    ingredients =
      case checkboxes.ingredients do
        true -> Search.search_for(Relaxir.Ingredients.Ingredient, :name, terms)
        _ -> []
      end

    usda =
      case checkboxes.usda do
        true -> Search.search_for(Relaxir.Ingredients.Food, :description, terms)
        _ -> []
      end

    count = Enum.reduce([recipes, categories, ingredients, usda], 0, fn i, acc -> acc + length(i) end)

    terms_for = Map.get(params, "for")
    list_id = Map.get(params, "id")

    render(conn, "search.html",
      current_user: current_user,
      count: count,
      checkboxes: checkboxes,
      for: terms_for,
      list_id: list_id,
      results: %{
        "recipes" => Enum.take(recipes, 20),
        "categories" => Enum.take(categories, 20),
        "ingredients" => Enum.take(ingredients, 20),
        "usda" => Enum.take(usda, 20)
      }
    )
  end
end
