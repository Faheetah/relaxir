defmodule RelaxirWeb.IngredientController do
  use RelaxirWeb, :controller

  alias Relaxir.Recipes
  alias Relaxir.Ingredients
  alias Relaxir.Ingredients.Ingredient

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    top_ingredients = Ingredients.top_ingredients()
    render(conn, "index.html", top_ingredients: top_ingredients, current_user: current_user)
  end

  def all(conn, %{"show" => "singular"}) do
    ingredients = Ingredients.list_ingredients_missing_singular()
    render(conn, "all.html", ingredients: ingredients, current_user: conn.assigns.current_user)
  end
  def all(conn, %{"show" => "parent"}) do
    ingredients = Ingredients.list_ingredients_missing_parent()
    render(conn, "all.html", ingredients: ingredients, current_user: conn.assigns.current_user)
  end
  def all(conn, _params) do
    ingredients = Ingredients.list_ingredients()
    render(conn, "all.html", ingredients: ingredients, current_user: conn.assigns.current_user)
  end

  def new(conn, _params) do
    changeset = Ingredients.change_ingredient(%Ingredient{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"ingredient" => ingredient_params}) do
    ingredient_params =
      ingredient_params
      |> maybe_add_parent_ingredient_id()
      |> maybe_add_source_recipe_id()

    case Ingredients.create_ingredient(ingredient_params) do
      {:ok, ingredient} ->
        redirect(conn, to: Routes.ingredient_path(conn, :show, ingredient))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  defp maybe_add_parent_ingredient_id(%{"parent_ingredient_name" => name} = ingredient) do
    case Ingredients.get_ingredient_by_name!(name) do
      nil -> ingredient
      %{id: id} -> Map.put(ingredient, "parent_ingredient_id", id)
    end
  end
  defp maybe_add_parent_ingredient_id(ingredient), do: ingredient

  defp maybe_add_source_recipe_id(%{"source_recipe_url" => ""} = ingredient), do: ingredient
  defp maybe_add_source_recipe_id(%{"source_recipe_url" => source_recipe_url} = ingredient) do
    %{host: host, path: path} = URI.parse(source_recipe_url)
    %{path_params: %{"id" => id}} = Phoenix.Router.route_info(RelaxirWeb.Router, "GET", path, host)
    {id, ""} = Integer.parse(id)

    case Recipes.get_recipe!(id) do
      nil -> ingredient
      %{id: id} -> Map.put(ingredient, "source_recipe_id", id)
    end
  end
  defp maybe_add_source_recipe_id(ingredient), do: ingredient


  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    ingredient = Ingredients.get_ingredient!(id)
    recipes = Ingredients.latest_recipes_for_ingredient(ingredient, 20)
    render(conn, "show.html", ingredient: ingredient, recipes: recipes, current_user: current_user)
  end

  def edit(conn, %{"id" => id}) do
    ingredient = Ingredients.get_ingredient!(id)
    changeset = Ingredients.change_ingredient(ingredient)
    render(conn, "edit.html", ingredient: ingredient, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ingredient" => ingredient_params}) do
    ingredient = Ingredients.get_ingredient!(id)

    ingredient_params =
      ingredient_params
      |> maybe_add_parent_ingredient_id()
      |> maybe_add_source_recipe_id()

    case Ingredients.update_ingredient(ingredient, ingredient_params) do
      {:ok, ingredient} ->
        conn
        |> put_flash(:info, "Ingredient updated successfully.")
        |> redirect(to: Routes.ingredient_path(conn, :show, ingredient))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", ingredient: ingredient, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    ingredient = Ingredients.get_ingredient!(id)
    {:ok, _ingredient} = Ingredients.delete_ingredient(ingredient)

    conn
    |> put_flash(:info, "Ingredient deleted successfully.")
    |> redirect(to: Routes.ingredient_path(conn, :index))
  end
end
