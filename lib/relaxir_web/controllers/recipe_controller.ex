defmodule RelaxirWeb.RecipeController do
  use RelaxirWeb, :controller

  alias Relaxir.Recipes
  alias Relaxir.Recipes.Recipe
  alias Relaxir.RecipeParser

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

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    recipe = Recipes.get_recipe!(id)

    meta_attrs = [
      %{property: "twitter:card", content: "summary_large_image"}, # required to make the image proper sized on some sites
      %{property: "og:ttl", content: "600"},
      %{property: "og:type", content: "image"},
      %{property: "og:site_name", content: "Relax+Dine"},
      %{property: "og:title", content: recipe.title},
      %{property: "og:description", content: recipe.description},
      %{property: "og:url", content: Path.join("https://www.relaxanddine.com", ~p"/recipes/#{recipe}")},
      %{property: "og:image", content: get_upload_path(recipe.image_filename)}
    ]

    render(conn, "show.html", recipe: recipe, current_user: current_user, meta_attrs: meta_attrs)
  end

  defp get_upload_path(nil), do: "https://www.relaxanddine.com/images/default-full.jpg"
  defp get_upload_path(file), do: "https://www.relaxanddine.com/uploads/#{file}-full.jpg"

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

  def delete(conn, %{"id" => id}) do
    recipe = Recipes.get_recipe!(id)
    {:ok, _recipe} = Recipes.delete_recipe(recipe)

    redirect(conn, to: Routes.recipe_path(conn, :index))
  end
end
