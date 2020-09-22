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
    recipes = try do
      search_for(Relaxir.Recipes.Recipe, :title, terms)
      |> Enum.take(20)
    catch
      :exit, _ -> ["RECIPE SEARCH OFFLINE"]
    end

    categories = try do
      search_for(Relaxir.Categories.Category, :name, terms)
      |> Enum.take(20)
    catch
      :exit, _ -> ["CATEGORY SEARCH OFFLINE"]
    end

    ingredients = try do
      search_for(Relaxir.Ingredients.Ingredient, :name, terms)
      |> Enum.take(20)
    catch
      :exit, _ -> ["INGREDIENT SEARCH OFFLINE"]
    end

    food = try do
      search_for(Relaxir.Ingredients.Food, :description, terms)
      |> Enum.take(20)
    catch
      :exit, _ -> ["USDA SEARCH OFFLINE"]
    end

    render(conn, "search.html", results: [Recipes: recipes, Categories: categories, Ingredients: ingredients, USDA: food])
  end

  def search(conn, _params) do
    render(conn, "search.html", results: [])
  end
end
