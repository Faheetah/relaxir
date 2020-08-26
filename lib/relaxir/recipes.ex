defmodule Relaxir.Recipes do
  import Ecto.Query
  alias Relaxir.Repo

  alias Relaxir.Categories
  alias Relaxir.Ingredients
  alias Relaxir.Recipes.Recipe

  @preload [:recipe_ingredients, :ingredients, :units, :recipe_categories, :categories]

  def list_recipes do
    Repo.all(Recipe)
  end

  def get_recipe!(id) do
    Recipe
    |> preload(^@preload)
    |> Repo.get!(id)
  end

  def create_recipe!(attrs) do
    {:ok, recipe} = create_recipe(attrs)
    recipe
  end

  def create_recipe(attrs) do
    attrs =
      attrs
      |> map_categories
      |> map_ingredients

    %Recipe{}
    |> Recipe.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, recipe} ->
        {:ok, Repo.preload(recipe, @preload)}

      error ->
        error
    end
  end

  def update_recipe(%Recipe{} = recipe, original_attrs) do
    attrs =
      original_attrs
      |> map_categories()
      |> map_existing_categories(recipe)
      |> map_ingredients()
      |> map_existing_ingredients(recipe)

    case attrs["errors"] do
      {:error, error} ->
        {
          :error,
          recipe
          |> Recipe.changeset(Map.merge(original_attrs, %{"ingredients" => attrs["errors"]}))
          |> Ecto.Changeset.add_error(:ingredients, error, validation: :required)
        }
      _ ->
        recipe
        |> Recipe.changeset(attrs)
        |> Repo.update()
        |> case do
          {:ok, recipe} ->
            {:ok, Repo.preload(recipe, [:recipe_ingredients, :ingredients, :recipe_categories, :categories])}

          error ->
            error
        end
    end
  end

  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
  end

  def map_categories(attrs) when is_map_key(attrs, "categories") do
    fetched_categories = Categories.get_categories_by_name!(attrs["categories"])

    categories =
      attrs["categories"]
      |> Enum.map(fn name ->
        case Enum.find(fetched_categories, fn c -> c.name == name end) do
          nil -> %{category: %{name: name}}
          category -> %{category_id: category.id}
        end
      end)

    Map.put(attrs, "recipe_categories", categories)
  end

  def map_categories(attrs), do: attrs

  def map_existing_categories(attrs, recipe) do
    current_recipe_categories = recipe.recipe_categories
    |> Enum.reduce([],
      fn (ri, acc) ->
        [%{id: ri.id, category: %{id: ri.category.id}} | acc]
      end
    )

    recipe_categories = (attrs["recipe_categories"] || [])
    |> Enum.map(fn i ->
      case i do
        %{:category_id => id} -> Enum.find(
          current_recipe_categories,
          %{recipe_id: recipe.id, category_id: id},
          fn cri ->
            if cri.category.id == id do
              cri
            end
          end)
        _ -> i
      end
    end)

    Map.put(attrs, "recipe_categories", recipe_categories)
  end

  def map_existing_ingredients(attrs, recipe) do
    current_recipe_ingredients = recipe.recipe_ingredients
    |> Enum.reduce([],
      fn (ri, acc) ->
        [%{id: ri.id, ingredient: %{id: ri.ingredient.id}} | acc]
      end
    )

    recipe_ingredients = attrs["recipe_ingredients"]
    |> Enum.map(fn i ->
      case i do
        %{:ingredient_id => id} -> Enum.find(
          current_recipe_ingredients,
          %{recipe_id: recipe.id, ingredient_id: id},
          fn cri ->
            if cri.ingredient.id == id do
              cri
            end
          end)
          |> Map.merge(%{
            note: Map.get(i, :note),
            amount: Map.get(i, :amount),
            unit_id: Map.get(i, :unit_id)
          })
        _ -> i
      end
    end)

    errors = Enum.find(
      recipe_ingredients,
      fn i ->
        case i do
          {:error, error} -> error
          _ -> nil
        end
      end)

    if errors != nil do
      Map.put(attrs, "errors", errors)
    else
      Map.put(attrs, "recipe_ingredients", recipe_ingredients)
    end
  end

  def map_ingredients(attrs) when is_map_key(attrs, "ingredients") do
    units = Ingredients.list_units()

    fetched_ingredients =
      attrs["ingredients"]
      |> Enum.map(fn i -> i.name end)
      |> Ingredients.get_ingredients_by_name!()

    ingredients =
      attrs["ingredients"]
      |> Enum.map(fn ingredient ->
        case Enum.find(fetched_ingredients, fn i -> i.name == ingredient.name end) do
          nil -> %{ingredient: ingredient}
          ingredient -> %{ingredient_id: ingredient.id}
        end
        |> map_recipe_ingredient_fields(ingredient, units)
      end)

    Map.put(attrs, "recipe_ingredients", ingredients)
  end

  def map_ingredients(attrs), do: attrs

  def map_recipe_ingredient_fields(attrs, ingredient, units) do
    amount = Map.get(ingredient, :amount)
    unit_name = Map.get(ingredient, :unit)

    cond do
      amount == nil -> attrs
      amount > 1 -> {:ok, Enum.find(units, fn u -> unit_name == u.plural end)}
      amount > 0 -> {:ok, Enum.find(units, fn u -> unit_name == u.singular end)}
      unit_name != nil -> {:error, "Unit \"#{unit_name}\" is invalid"}
      true -> attrs
    end
    |> case do
      {:ok, nil} ->
        {:error, "Unit \"#{unit_name}\" was not found"}

      {:ok, unit} ->
        attrs
        |> Map.merge(%{
          amount: Map.get(ingredient, :amount),
          unit_id: unit.id,
          note: Map.get(ingredient, :note)
        })

      {:error, error} ->
        {:error, error}

      %{ingredient: %{note: note}} ->
        attrs
        |> Map.merge(%{note: note})

      attrs ->
        attrs
        |> Map.merge(%{note: Map.get(ingredient, :note)})
    end
  end
end
