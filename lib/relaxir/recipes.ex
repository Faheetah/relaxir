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
          order_by: ri.order,
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

  # Delimiter for serializing ingredients - using :: to avoid conflicts with ingredient names
  @ingredient_delimiter "||"

  defp format_ingredient(recipe_ingredient) do
    amount = recipe_ingredient.amount || ""
    unit_name = if recipe_ingredient.unit, do: recipe_ingredient.unit.name, else: ""
    note = recipe_ingredient.note || ""

    Enum.join([amount, unit_name, recipe_ingredient.ingredient.name, note], @ingredient_delimiter)
  end

  # Parse ingredient using the new Unit library
  def parse_ingredient_with_units(unparsed) do
    # Strip note temporarily to help unit parsing — the Unit library
    # cannot handle commas (e.g. "1 cup, noted" fails to parse the unit).
    {unit_part, note} =
      case String.split(unparsed, ",", parts: 2) do
        [part] -> {part, ""}
        [part, rest] -> {part, String.trim(rest)}
      end

    # Only accept weight or volume units (not temperature, etc.)
    parsed_result =
      case Relaxir.Units.parse_unit_string_weight(unit_part) do
        {:ok, unit, rest} ->
          {:ok, unit, rest, note}

        {:error, _reason} ->
          case Relaxir.Units.parse_unit_string_volume(unit_part) do
            {:ok, unit, rest} -> {:ok, unit, rest, note}
            {:error, _reason} -> {:error, :no_valid_unit}
          end
      end

    case parsed_result do
      {:error, _reason} ->
        # If unit parsing fails, try to parse as count-based ingredient (e.g., "3 eggs")
        parse_count_based_ingredient(unparsed)

      {:ok, unit, rest, note} ->
        # Check if this unit parse looks suspicious (e.g., single letter unit consuming part of a word)
        if suspicious_unit_parse?(unit_part, unit, rest) do
          # Fall back to count-based parsing
          parse_count_based_ingredient(unparsed)
        else
          amount = unit.value
          unit_str = Relaxir.Units.get_unit_name(unit)

          # Extract ingredient name from remaining text after unit
          ingredient = String.trim(rest)

          # If there was trailing text after the unit *and* a comma-note,
          # the trailing text is the ingredient and the comma-part is the note.
          # If there was no trailing text after the unit, the comma-part is still the note
          # but the ingredient will be empty (which the caller rejects as invalid).
          full_note =
            case {note, ingredient} do
              {"", ""} -> ""
              {note, ""} -> note
              {"", _rest} -> ""
              {note, _rest} -> note
            end

          {:ok, [Float.to_string(amount), unit_str, ingredient, full_note]}
        end
    end
  end

  defp suspicious_unit_parse?(original, unit, rest) do
    # Returns true (suspicious) only if:
    # 1. rest is not empty AND
    # 2. unit word was NOT found in original AND
    # 3. a single-letter unit consumed part of a word
    rest != "" and not unit_word_found?(original, unit) and single_letter_consumed?(unit, rest)
  end

  defp single_letter_consumed?(unit, _rest) do
    alias = Map.get(unit, :alias, "")
    singular = unit.singular
    String.length(alias) == 1 || String.length(singular) == 1
  end

  defp unit_word_found?(original, unit) do
    original_lower = String.downcase(original)
    singular = String.downcase(unit.singular)
    singular_pattern = ~r/(^|\s)#{Regex.escape(singular)}(\s|$)/i

    Regex.match?(singular_pattern, original_lower) ||
      (Map.has_key?(unit, :plural) && Regex.match?(~r/(^|\s)#{Regex.escape(String.downcase(unit.plural))}(\s|$)/i, original_lower)) ||
      (Map.has_key?(unit, :alias) && Regex.match?(~r/(^|\s)#{Regex.escape(String.downcase(unit.alias))}(\s|$)/i, original_lower))
  end

  defp parse_count_based_ingredient(unparsed) do
    trimmed = String.trim(unparsed)

    # Try to parse a fraction (e.g., "1/2", "3/4") at the beginning
    case parse_fraction_prefix(trimmed) do
      {:ok, amount_str, rest} ->
        rest = String.trim(rest)

        # Extract note if present
        [ingredient_part | note_parts] = String.split(rest, ",", parts: 2) |> Enum.map(&String.trim/1)
        note = if length(note_parts) > 0, do: hd(note_parts), else: ""
        ingredient = String.trim(ingredient_part)

        {:ok, [amount_str, "", ingredient, note]}

      :error ->
        # Try to extract a decimal number at the beginning
        case Float.parse(trimmed) do
          {amount, rest} ->
            rest = String.trim(rest)

            # Extract note if present
            [ingredient_part | note_parts] = String.split(rest, ",", parts: 2) |> Enum.map(&String.trim/1)
            note = if length(note_parts) > 0, do: hd(note_parts), else: ""
            ingredient = String.trim(ingredient_part)

            {:ok, [Float.to_string(amount), "", ingredient, note]}

          :error ->
            # No number at the beginning, treat as ingredient only
            [ingredient_part | note_parts] = String.split(trimmed, ",", parts: 2) |> Enum.map(&String.trim/1)
            note = if length(note_parts) > 0, do: hd(note_parts), else: ""
            ingredient = String.trim(ingredient_part)

            {:ok, ["", "", ingredient, note]}
        end
    end
  end

  # Parse a fraction like "1/2" or "3/4" at the beginning of a string
  defp parse_fraction_prefix(string) do
    case Regex.run(~r/^(\d+)\/(\d+)\s*(.*)$/, string) do
      [_, numerator, denominator, rest] ->
        amount_str = "#{numerator}/#{denominator}"
        {:ok, amount_str, rest}

      nil ->
        :error
    end
  end

  def get_units() do
    Relaxir.Units.list_units()
  end

  @doc """
  Search for recipes by title prefix (for live_select autocomplete)
  """
  def search_recipes(query) when is_binary(query) do
    query =
      from r in Recipe,
        where: ilike(r.title, ^"#{query}%"),
        order_by: [asc: r.title],
        limit: 20

    Repo.all(query)
    |> Enum.map(& &1.title)
  end

  def search_recipes(_), do: []

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

  @doc """
  Creates an ingredient from a recipe, allowing the recipe to be used as an ingredient in other recipes.
  """
  def create_ingredient_from_recipe(%Recipe{} = recipe) do
    attrs = %{
      "name" => recipe.title,
      "singular" => Inflex.singularize(recipe.title),
      "description" => "From recipe: #{recipe.title}",
      "source_recipe_id" => recipe.id
    }

    Relaxir.Ingredients.create_ingredient(attrs)
  end

  @doc """
  Gets or creates an ingredient from a recipe. Returns the existing ingredient if one already exists.
  """
  def get_or_create_ingredient_from_recipe(%Recipe{} = recipe) do
    # Use lowercase name for lookup since ingredient names are stored lowercase
    case Relaxir.Ingredients.get_ingredient_by_name(String.downcase(recipe.title)) do
      nil -> create_ingredient_from_recipe(recipe)
      ingredient -> {:ok, ingredient}
    end
  end
end
