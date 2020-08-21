defmodule RelaxirWeb.RecipeController do
  use RelaxirWeb, :controller

  alias Relaxir.Recipes
  alias Relaxir.Recipes.Recipe
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

  def parse_attrs(attrs) do
    attrs
    |> split_field("categories", ",")
    |> split_field("ingredients", "\n")
    |> parse_ingredients()
  end

  def split_field(attrs, name, separator) do
    field =
      (attrs[name] || "")
      |> String.split(separator)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    Map.put(attrs, name, field)
  end

  def parse_ingredients(attrs) do
    ingredients =
      attrs["ingredients"]
      |> Enum.map(&(%{name: &1}))

    Map.put(attrs, "ingredients", ingredients)
  end
end
