defmodule RelaxirWeb.RecipeController do
  use RelaxirWeb, :controller

  alias Relaxir.Recipes
  alias Relaxir.Ingredients
  alias Relaxir.Recipes.Recipe
  alias RelaxirWeb.Authentication
  alias RelaxirWeb.RecipeParser

  def index(conn, _params) do
    current_user = Authentication.get_current_user(conn)
    recipes = Recipes.list_recipes()
    render(conn, "index.html", recipes: recipes, current_user: current_user)
  end

  def new(conn, %{"recipe" => recipe}) do
    attrs = RecipeParser.parse_attrs(recipe)
    changeset = Recipes.change_recipe(%Recipe{}, attrs)
    ingredients = map_ingredients(attrs)
    render(conn, "new.html", ingredients: ingredients, changeset: changeset)
  end

  def new(conn, _params) do
    changeset = Recipes.change_recipe(%Recipe{recipe_ingredients: [], categories: []})
    render(conn, "new.html", ingredients: [], changeset: changeset)
  end

  def get_recipe_category_names(changeset) do
    changeset
    |> Map.get(:changes)
    |> Map.get(:recipe_categories)
    |> Enum.map(fn c ->
      case c.changes do
        %{category_id: id} ->
          name = Relaxir.Repo.get!(Relaxir.Categories.Category, id).name

          %{changes: %{category_id: id, category: %{changes: %{name: name}}}}
          |> IO.inspect()

        _ ->
          c
      end
    end)
  end

  def confirm_new(conn, %{"recipe" => recipe_params}) do
    attrs =
      recipe_params
      |> RecipeParser.parse_attrs()

    changeset = Recipes.change_recipe(%Recipe{}, attrs)
    recipe_categories = get_recipe_category_names(changeset)

    case changeset do
      %{valid?: false} ->
        ingredients = map_ingredients(attrs)
        render(conn, "new.html", changeset: changeset, ingredients: ingredients)

      _ ->
        render(conn, "confirm_new.html", recipe_categories: recipe_categories, recipe_params: recipe_params, changeset: changeset)
    end
  end

  def map_ingredients(attrs) do
    attrs
    |> Recipes.map_ingredients()
    |> Map.get("recipe_ingredients")
    |> Enum.map(fn i ->
      case i do
        %{ingredient_id: id} ->
          Map.put(
            i,
            :ingredient,
            Relaxir.Repo.get!(Ingredients.Ingredient, id)
          )

        i ->
          i
      end
    end)
    |> Enum.map(fn i ->
      case i do
        %{unit_id: id} -> Map.put(i, :unit, Relaxir.Repo.get!(Ingredients.Unit, id))
        i -> i
      end
    end)
  end

  def create(conn, %{"recipe" => recipe_params}) do
    case Recipes.create_recipe(RecipeParser.parse_attrs(recipe_params)) do
      {:ok, recipe} ->
        conn
        |> put_flash(:info, "Recipe created successfully.")
        |> redirect(to: Routes.recipe_path(conn, :show, recipe))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, ingredients: map_ingredients(recipe_params))
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = Authentication.get_current_user(conn)
    recipe = Recipes.get_recipe!(id)
    render(conn, "show.html", recipe: recipe, current_user: current_user)
  end

  def edit(conn, %{"id" => id, "recipe" => recipe}) do
    attrs = RecipeParser.parse_attrs(recipe)
    changeset = Recipes.change_recipe(%Recipe{}, attrs)
    ingredients = map_ingredients(attrs)
    recipe = Recipes.get_recipe!(id)
    render(conn, "edit.html", recipe: recipe, ingredients: ingredients, changeset: changeset)
  end

  def edit(conn, %{"id" => id}) do
    recipe = Recipes.get_recipe!(id)
    changeset = Recipes.change_recipe(recipe)
    render(conn, "edit.html", recipe: recipe, ingredients: recipe.recipe_ingredients, changeset: changeset)
  end

  def confirm_update(conn, %{"id" => id, "recipe" => recipe_params}) do
    recipe = Recipes.get_recipe!(id)

    attrs =
      recipe_params
      |> RecipeParser.parse_attrs()

    changeset = Recipes.change_recipe(%Recipe{}, attrs)
    recipe_categories = get_recipe_category_names(changeset)

    case changeset do
      %{valid?: false} ->
        ingredients = map_ingredients(attrs)
        render(conn, "new.html", changeset: changeset, ingredients: ingredients)

      _ ->
        render(conn, "confirm_update.html", recipe_categories: recipe_categories, recipe: recipe, recipe_params: recipe_params, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "recipe" => recipe_params}) do
    recipe = Recipes.get_recipe!(id)

    case Recipes.update_recipe(recipe, RecipeParser.parse_attrs(recipe_params)) do
      {:ok, recipe} ->
        conn
        |> put_flash(:info, "Recipe updated successfully.")
        |> redirect(to: Routes.recipe_path(conn, :show, recipe))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", recipe: recipe, ingredients: recipe.recipe_ingredients, changeset: %{changeset | action: :insert})
    end
  end

  def delete(conn, %{"id" => id}) do
    recipe = Recipes.get_recipe!(id)
    {:ok, _recipe} = Recipes.delete_recipe(recipe)

    conn
    |> put_flash(:info, "Recipe deleted successfully.")
    |> redirect(to: Routes.recipe_path(conn, :index))
  end
end
