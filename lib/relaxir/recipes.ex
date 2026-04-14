defmodule Relaxir.Recipes do
  @moduledoc """
  Provides functions for managing recipes in the Relaxir application.

  This module handles all recipe-related operations including:
  - Listing recipes
  - Creating, updating, and deleting recipes
  - Managing recipe ingredients and categories
  - Parsing ingredient strings
  - Handling recipe images

  The module also provides utility functions for working with recipe data
  and preparing it for display in the web interface.
  """

  import Ecto.Query

  import Ecto.Query

  alias Relaxir.Repo
  alias Relaxir.Categories.Category
  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.RecipeIngredient
  alias Relaxir.Recipes.Recipe
  alias Relaxir.Units.Unit

  @preloads [
    [
      recipe_ingredients:
        from(
          ri in RecipeIngredient,
          left_join: i in Ingredient,
          on: i.id == ri.ingredient_id,
          order_by: i.name,
          preload: [ingredient: [source_recipe: [recipe_ingredients: [:ingredient]]]]
        )
    ],
    :categories,
    :user
  ]

  def list_recipes(current_user?) do
    published = if current_user?, do: [], else: [published: true]

    Repo.all(
      from r in Recipe,
        where: ^published,
        order_by: [desc: r.inserted_at],
        preload: [:user, :categories]
    )
  end

  def get_recipe!(id) do
    Recipe
    |> preload(^@preloads)
    |> Repo.get!(id)
  end

  def get_recipe_by_name!(title) do
    Repo.get_by(Relaxir.Recipes.Recipe, title: title)
  end

  def create_recipe!(attrs) do
    {:ok, recipe} = create_recipe(attrs)
    recipe
  end

  def create_recipe(attrs) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> Repo.insert()
    |> then(&maybe_preload_recipe/1)
  end

  defp maybe_preload_recipe({:ok, recipe}), do: {:ok, Repo.preload(recipe, @preloads)}
  defp maybe_preload_recipe(error), do: error

  def update_image_filename(recipe, image_filename) do
    update_recipe(recipe, %{"image_filename" => image_filename})
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.changeset(attrs)
    |> Repo.update()
  end

  # sobelow_skip ["Traversal"]
  # traversal is not possible due to dest coming from application config
  def delete_recipe(%Recipe{} = recipe) do
    if recipe.image_filename do
      dest = Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]
      Relaxir.Uploader.remove_previous(dest, recipe.image_filename)
    end

    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
    |> map_ingredients(recipe, attrs)
    |> map_categories(recipe, attrs)
  end

  defp map_categories(changeset, recipe, attrs) do
    changes = Map.put(changeset.changes, :categories, attrs["categories"] || Enum.map(recipe.categories, & &1.name))
    Map.put(changeset, :changes, changes)
  end

  # Takes a changeset and returns a changeset with ingredients mapped as a list of strings
  defp map_ingredients(changeset, _recipe, %{"recipe_ingredients_empty_selection" => ""}), do: changeset

  defp map_ingredients(changeset, recipe, attrs) do
    changes =
      Map.put(
        changeset.changes,
        :recipe_ingredients,
        attrs["recipe_ingredients"] || Enum.map(recipe.recipe_ingredients, &format_ingredient/1)
      )

    Map.put(changeset, :changes, changes)
  end

  defp format_ingredient(recipe_ingredient) do
    amount = recipe_ingredient.amount || ""
    unit_name = if recipe_ingredient.unit, do: recipe_ingredient.unit.name, else: ""
    note = recipe_ingredient.note || ""

    Enum.join([amount, unit_name, recipe_ingredient.ingredient.name, note], "|")
  end

  # Parse ingredient using the new Unit library
  def parse_ingredient_with_units(unparsed) do
    # Try parsing with specific measurement types to avoid conflicts (e.g., c for celsius vs cups)
    parsed_result =
      case Relaxir.Units.parse_unit_string_weight(unparsed) do
        {:ok, unit, rest} -> {:ok, unit, rest}
        {:error, _reason} ->
          case Relaxir.Units.parse_unit_string_volume(unparsed) do
            {:ok, unit, rest} -> {:ok, unit, rest}
            {:error, _reason} -> Relaxir.Units.parse_unit_string(unparsed)
          end
      end

    case parsed_result do
      {:error, reason} ->
        {:error, reason}

      {:ok, :error, _rest} ->
        {:error, "Could not parse unit"}

      {:ok, unit, rest} ->
        amount = unit.value
        unit_str = Relaxir.Units.get_unit_name(unit)

        # Extract note if present
        [ingredient_part | note_parts] = String.split(rest, ",", parts: 2) |> Enum.map(&String.trim/1)
        note = if length(note_parts) > 0, do: hd(note_parts), else: ""

        # Extract ingredient name
        ingredient = String.trim(ingredient_part)

        {:ok, [Float.to_string(amount), unit_str, ingredient, note]}
    end
  end

  def get_units() do
    Relaxir.Units.list_units()
  end

  def get_recipe_ingredient_names(changeset) do
    changeset
    |> Map.get(:changes)
    |> Map.get(:recipe_ingredients)
    |> Enum.map(&get_ingredient_name/1)
  end

  defp get_ingredient_name(%{changes: %{ingredient_id: id}} = ingredient) do
    name = Relaxir.Repo.get!(Ingredient, id).name
    Map.merge(ingredient, %{changes: %{ingredient: %{changes: %{name: name}}}}, fn _, m1, m2 -> Map.merge(m1, m2) end)
  end

  defp get_ingredient_name(%{changes: %{unit_id: id}} = ingredient) do
    unit = Relaxir.Repo.get!(Unit, id)

    cond do
      Map.get(ingredient.changes, :amount) == nil -> ingredient
      ingredient.changes.amount > 1 -> merge_ingredient_changes(ingredient, Inflex.pluralize(unit.name))
      true -> merge_ingredient_changes(ingredient, Inflex.singularize(unit.name))
    end
  end

  defp get_ingredient_name(ingredient), do: ingredient

  defp merge_ingredient_changes(ingredient, unit_name) do
    Map.merge(ingredient, %{changes: %{unit: unit_name}}, fn _, m1, m2 -> Map.merge(m1, m2) end)
  end

  def get_recipe_category_names(changeset) do
    changeset
    |> Map.get(:changes)
    |> Map.get(:recipe_categories)
    |> Enum.map(fn c ->
      case c.changes do
        %{category_id: id} ->
          name = Relaxir.Repo.get!(Category, id).name

          %{changes: %{category_id: id, category: %{changes: %{name: name}}}}

        _ ->
          c
      end
    end)
  end
end
