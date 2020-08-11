defmodule RelaxirWeb.RecipeController do
  use RelaxirWeb, :controller

  alias Relaxir.Recipes
  alias Relaxir.Recipes.Recipe
  alias Relaxir.Ingredients
  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.Categories
  alias Relaxir.Categories.Category
  alias RelaxirWeb.Authentication

  def index(conn, _params) do
    current_user = Authentication.get_current_user(conn)
    recipes = Recipes.list_recipes()
    render(conn, "index.html", recipes: recipes, current_user: current_user)
  end

  def new(conn, _params) do
    changeset = Recipes.change_recipe(%Recipe{ingredients: [], categories: []})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"recipe" => recipe_params}) do
    case Recipes.create_recipe(parse_attrs(recipe_params)) do
      {:ok, recipe} ->
        conn
        |> put_flash(:info, "Recipe created successfully.")
        |> redirect(to: Routes.recipe_path(conn, :show, recipe))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = Authentication.get_current_user(conn)
    recipe = Recipes.get_recipe!(id)
    render(conn, "show.html", recipe: recipe, current_user: current_user)
  end

  def edit(conn, %{"id" => id}) do
    recipe = Recipes.get_recipe!(id)
    changeset = Recipes.change_recipe(recipe)
    render(conn, "edit.html", recipe: recipe, changeset: changeset)
  end

  def update(conn, %{"id" => id, "recipe" => recipe_params}) do
    recipe = Recipes.get_recipe!(id)

    case Recipes.update_recipe(recipe, parse_attrs(recipe_params)) do
      {:ok, recipe} ->
        conn
        |> put_flash(:info, "Recipe updated successfully.")
        |> redirect(to: Routes.recipe_path(conn, :show, recipe))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", recipe: recipe, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    recipe = Recipes.get_recipe!(id)
    {:ok, _recipe} = Recipes.delete_recipe(recipe)

    conn
    |> put_flash(:info, "Recipe deleted successfully.")
    |> redirect(to: Routes.recipe_path(conn, :index))
  end

  defp parse_attrs(attrs) do
    attrs
    |> update_in(["categories"], &parse_categories/1)
    |> update_in(["ingredients"], &parse_ingredients/1)
  end

  defp parse_categories(category) do
    category |> IO.inspect
    (category || "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(& &1 == "")
    |> Enum.map(&get_or_create_category/1)
  end

  defp get_or_create_category(category) do
    case Categories.get_category_by_name!(category) do
      nil -> Category.changeset(%Category{}, %{name: category})
      category -> category
    end
  end

  defp parse_ingredients(ingredient) do
    (ingredient || "")
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(& &1 == "")
    |> Enum.map(&get_or_create_ingredient/1)
  end

  defp get_or_create_ingredient(ingredient) do
    case Ingredients.get_ingredient_by_name!(ingredient) do
      nil -> Ingredient.changeset(%Ingredient{}, %{name: ingredient})
      ingredient -> ingredient
    end
  end
end
