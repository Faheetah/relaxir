defmodule RelaxirWeb.RecipeController do
  use RelaxirWeb, :controller

  alias Relaxir.Recipes
  alias Relaxir.Recipes.Recipe
  alias RelaxirWeb.RecipeParser

  def index(conn, %{"show" => show}) do
    current_user = conn.assigns.current_user

    recipes =
      case show do
        "all" -> Recipes.list_recipes()
        "drafts" -> Recipes.list_draft_recipes()
        "draft" -> Recipes.list_draft_recipes()
        _ -> Recipes.list_published_recipes()
      end

    render(conn, "index.html", recipes: recipes, current_user: current_user, show: show)
  end

  def index(conn, _params) do
    index(conn, %{"show" => "published"})
  end

  def new(conn, %{"recipe" => recipe}) do
    attrs = RecipeParser.parse_attrs(recipe)
    changeset = Recipes.change_recipe(%Recipe{}, attrs)
    ingredients = Recipes.map_ingredients(attrs)
    render(conn, "new.html", ingredients: ingredients, changeset: changeset)
  end

  def new(conn, _params) do
    changeset = Recipes.change_recipe(%Recipe{recipe_ingredients: [], categories: []})
    render(conn, "new.html", ingredients: [], changeset: changeset)
  end

  def confirm_new(conn, %{"recipe" => recipe_params}) do
    attrs =
      recipe_params
      |> RecipeParser.parse_attrs()

    changeset = Recipes.change_recipe(%Recipe{}, attrs)
    recipe_categories = Recipes.get_recipe_category_names(changeset)
    recipe_ingredients = Recipes.get_recipe_ingredient_suggestions(changeset)

    case changeset do
      %{valid?: false} ->
        ingredients = Recipes.map_ingredients(attrs)
        render(conn, "new.html", changeset: changeset, ingredients: ingredients)

      _ ->
        render(
          conn,
          "confirm_new.html",
          recipe_categories: recipe_categories,
          recipe_ingredients: recipe_ingredients,
          recipe_params: recipe_params,
          changeset: changeset
        )
    end
  end

  def create(conn, %{"recipe" => recipe_params}) do
    current_user = conn.assigns.current_user

    recipe =
      recipe_params
      |> RecipeParser.parse_attrs()
      |> Map.put("user_id", Map.get(current_user, :id))

    case Recipes.create_recipe(recipe) do
      {:ok, recipe} ->
        conn
        |> put_flash(:info, "Recipe created successfully.")
        |> redirect(to: Routes.recipe_path(conn, :show, recipe))

      {:error, %Ecto.Changeset{} = changeset} ->
        ingredients =
          recipe_params
          |> RecipeParser.parse_attrs()
          |> Recipes.map_ingredients()

        render(conn, "new.html", changeset: changeset, ingredients: ingredients)
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    recipe = Recipes.get_recipe!(id)
    render(conn, "show.html", recipe: recipe, current_user: current_user)
  end

  def edit(conn, %{"id" => id, "recipe" => recipe}) do
    attrs = RecipeParser.parse_attrs(recipe)
    changeset = Recipes.change_recipe(%Recipe{}, attrs)
    ingredients = Recipes.map_ingredients(attrs)
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
    recipe_categories = Recipes.get_recipe_category_names(changeset)
    recipe_ingredients = Recipes.get_recipe_ingredient_suggestions(changeset)

    case changeset do
      %{valid?: false} ->
        ingredients = Recipes.map_ingredients(attrs)
        render(conn, "edit.html", recipe: recipe, changeset: %{changeset | action: :insert}, ingredients: ingredients)

      _ ->
        render(conn, "confirm_update.html",
          recipe_categories: recipe_categories,
          recipe_ingredients: recipe_ingredients,
          recipe: recipe,
          recipe_params: recipe_params,
          changeset: changeset
        )
    end
  end

  def update(conn, %{"id" => id, "recipe" => recipe_params}) do
    recipe = Recipes.get_recipe!(id)

    ingredients =
      recipe_params
      |> RecipeParser.parse_attrs()
      |> Recipes.map_ingredients()

    case Recipes.update_recipe(recipe, RecipeParser.parse_attrs(recipe_params)) do
      {:ok, recipe} ->
        conn
        |> put_flash(:info, "Recipe updated successfully.")
        |> redirect(to: Routes.recipe_path(conn, :show, recipe))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", recipe: recipe, ingredients: ingredients, changeset: %{changeset | action: :insert})
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
