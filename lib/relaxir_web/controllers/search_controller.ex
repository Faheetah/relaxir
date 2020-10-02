defmodule RelaxirWeb.SearchController do
  use RelaxirWeb, :controller

  def search_for(module, name, terms) do
    case Relaxir.Search.get(module, name, terms) do
      {:ok, results} -> results
      {:error, :not_found} -> []
    end
    |> Enum.map(fn {i, _} -> i end)
  end

  def search(conn, %{"terms" => terms}) do
    recipes = try do
      search_for(Relaxir.Recipes.Recipe, :title, terms)
    catch
      :exit, _ -> ["RECIPE SEARCH OFFLINE"]
    end

    categories = try do
      search_for(Relaxir.Categories.Category, :name, terms)
    catch
      :exit, _ -> ["CATEGORY SEARCH OFFLINE"]
    end

    ingredients = try do
      search_for(Relaxir.Ingredients.Ingredient, :name, terms)
    catch
      :exit, _ -> ["INGREDIENT SEARCH OFFLINE"]
    end

    food = try do
      search_for(Relaxir.Ingredients.Food, :description, terms)
    catch
      :exit, _ -> ["USDA SEARCH OFFLINE"]
    end

    count = Enum.reduce([recipes, categories, ingredients, food], 0, fn i, acc -> acc + length(i) end)
    render(conn, "search.html", count: count, results: %{
      "recipes" => Enum.take(recipes, 20),
      "categories" => Enum.take(categories, 20),
      "ingredients" => Enum.take(ingredients, 20),
      "usda" => Enum.take(food, 20)
    })
  end

  def search(conn, _params) do
    render(conn, "search.html", count: :na, results: [])
  end
end
