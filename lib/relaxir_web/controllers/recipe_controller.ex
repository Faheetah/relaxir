defmodule RelaxirWeb.RecipeController do
  use RelaxirWeb, :controller

  import Ecto.Changeset

  alias Relaxir.Recipes
  alias Relaxir.Ingredients
  alias Relaxir.Recipes.Recipe
  alias RelaxirWeb.Authentication
  alias RelaxirWeb.RecipeParser

  def index(conn, %{"show" => show}) do
    current_user = Authentication.get_current_user(conn)

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
    ingredients = map_ingredients(attrs)
    render(conn, "new.html", ingredients: ingredients, changeset: changeset)
  end

  def new(conn, _params) do
    changeset = Recipes.change_recipe(%Recipe{recipe_ingredients: [], categories: []})
    render(conn, "new.html", ingredients: [], changeset: changeset)
  end

  def get_recipe_ingredient_names(changeset) do
    changeset
    |> Map.get(:changes)
    |> Map.get(:recipe_ingredients)
    |> Enum.map(fn i ->
      case i.changes do
        %{ingredient_id: id} ->
          name = Relaxir.Repo.get!(Relaxir.Ingredients.Ingredient, id).name
          Map.merge(i, %{changes: %{ingredient: %{changes: %{name: name}}}}, fn _, m1, m2 -> Map.merge(m1, m2) end)

        _ ->
          i
      end
    end)
    |> Enum.map(fn i ->
      case i.changes do
        %{unit_id: id} ->
          unit = Relaxir.Repo.get!(Ingredients.Unit, id)

          cond do
            Map.get(i.changes, :amount) == nil -> i
            i.changes.amount > 1 -> Map.merge(i, %{changes: %{unit: Inflex.pluralize(unit.name)}}, fn _, m1, m2 -> Map.merge(m1, m2) end)
            true -> Map.merge(i, %{changes: %{unit: Inflex.singularize(unit.name)}}, fn _, m1, m2 -> Map.merge(m1, m2) end)
          end

        _ ->
          i
      end
    end)
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

    recipe_ingredients = get_recipe_ingredient_suggestions(changeset)

    case changeset do
      %{valid?: false} ->
        ingredients = map_ingredients(attrs)
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

  def map_ingredients(attrs) do
    attrs
    |> Ingredients.Parser.map_ingredients()
    |> Map.get("recipe_ingredients", [])
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
    current_user = Authentication.get_current_user(conn)
    recipe = recipe_params
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
          |> map_ingredients()

        render(conn, "new.html", changeset: changeset, ingredients: ingredients)
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

  def get_recipe_ingredient_suggestions(changeset) do
    changeset
    |> get_recipe_ingredient_names()
    |> Enum.map(fn ingredient ->
      ingredient_name =
        ingredient
        |> Map.get(:changes)
        |> Map.get(:ingredient)
        |> Map.get(:changes)
        |> Map.get(:name)

      cond do
        ingredient_name == nil ->
          ingredient

        true ->
          case Relaxir.Search.get(Ingredients.Ingredient, :name, ingredient_name) do
            {:ok, suggestion} ->
              {{_, s, _}, score} = hd(suggestion)

              cond do
                score > 1 ->
                  put_change(ingredient, :suggestion, %{name: String.downcase(s), type: "ingredient", score: round(score * 10)})

                true ->
                  case Relaxir.Search.get(Ingredients.Food, :description, ingredient_name) do
                    {:ok, suggestion} ->
                      {{_, s, _}, score} = hd(suggestion)

                      cond do
                        score > 1 ->
                          put_change(ingredient, :suggestion, %{name: String.downcase(s), type: "USDA", score: round(score * 10)})

                        true ->
                          ingredient
                      end

                    {:error, :not_found} ->
                      ingredient
                  end
              end

            {:error, :not_found} ->
              case Relaxir.Search.get(Ingredients.Food, :description, ingredient_name) do
                {:ok, suggestion} ->
                  {{_, s, _}, score} = hd(suggestion)

                  cond do
                    score > 1 -> put_change(ingredient, :suggestion, %{name: String.downcase(s), type: "USDA", score: round(score * 10)})
                    true -> ingredient
                  end

                {:error, :not_found} ->
                  ingredient
              end
          end
      end
    end)
  end

  def confirm_update(conn, %{"id" => id, "recipe" => recipe_params}) do
    recipe = Recipes.get_recipe!(id)

    attrs =
      recipe_params
      |> RecipeParser.parse_attrs()

    changeset = Recipes.change_recipe(%Recipe{}, attrs)
    recipe_categories = get_recipe_category_names(changeset)
    recipe_ingredients = get_recipe_ingredient_suggestions(changeset)

    case changeset do
      %{valid?: false} ->
        ingredients = map_ingredients(attrs)
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
      |> map_ingredients()

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
