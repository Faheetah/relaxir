defmodule RelaxirWeb.RecipeController do
  use RelaxirWeb, :controller

  alias Relaxir.Recipes
  alias Relaxir.Recipes.Recipe
  alias Relaxir.RecipeParser

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

  def create(conn, %{"recipe" => recipe_params}) do
    current_user = conn.assigns.current_user

    recipe =
      recipe_params
      |> RecipeParser.parse_attrs()
      |> Map.put("user_id", Map.get(current_user, :id))

    case Recipes.create_recipe(recipe) do
      {:ok, recipe} ->
        redirect(conn, to: "/recipes/#{recipe.id}")

      {:error, %Ecto.Changeset{} = changeset} ->
        ingredients =
          recipe_params
          |> RecipeParser.parse_attrs()
          |> Recipes.map_ingredients()

        render(conn, "new.html", changeset: changeset, ingredients: ingredients)
    end
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

  def update(conn, %{"id" => id, "recipe" => recipe_params}) do
    recipe = Recipes.get_recipe!(id)

    case Recipes.update_recipe(recipe, RecipeParser.parse_attrs(recipe_params)) do
      {:ok, recipe} ->
        redirect(conn, to: "/recipes/#{recipe.id}")

      {:error, %Ecto.Changeset{} = changeset} ->
        # this is only for rendering purposes on errors, could we move this into `recipe`?
        ingredients =
            recipe_params
            |> RecipeParser.parse_attrs()
            |> Recipes.map_ingredients()
        render(conn, "edit.html", recipe: recipe, ingredients: ingredients, changeset: %{changeset | action: :insert})
    end
  end
end
