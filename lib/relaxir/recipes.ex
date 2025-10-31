defmodule Relaxir.Recipes do
  @moduledoc false

  import Ecto.Query

  alias Relaxir.Repo
  alias Relaxir.Categories.Category
  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.RecipeIngredient
  alias Relaxir.Recipes.Recipe
  alias Relaxixr.Units.Unit

  @preloads [
    [recipe_ingredients: from(
      ri in RecipeIngredient,
      left_join: i in Ingredient,
      on: i.id == ri.ingredient_id,
      order_by: i.name,
      preload: [:unit, ingredient: [source_recipe: [recipe_ingredients: [:ingredient, :unit]]]]
    )],
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
    dest = Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]

    # TODO move this to a separate module to handle physical file access
    if recipe.image_filename do
      :ok = File.rm(Path.join(dest, "#{recipe.image_filename}-full.jpg"))
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
  defp map_ingredients(changeset, recipe, %{"recipe_ingredients_empty_selection" => ""}), do: changeset
  defp map_ingredients(changeset, recipe, attrs) do
    changes = Map.put(changeset.changes, :recipe_ingredients, attrs["recipe_ingredients"] || Enum.map(recipe.recipe_ingredients, &format_ingredient/1))
    Map.put(changeset, :changes, changes)
  end

  defp format_ingredient(recipe_ingredient) do
    amount = recipe_ingredient.amount || ""
    unit = recipe_ingredient.unit || %{name: ""}
    note = recipe_ingredient.note || ""

    Enum.join([amount, unit.name, recipe_ingredient.ingredient.name, note], "|")
  end

  # Parse out units, ingredients, amounts, and note
  # start by splitting, then downcase and singularize, then match, then recombine
  def parse_ingredient(unparsed, units) do
    [terms | note] =
      String.split(unparsed, ",", trim: true, parts: 2)
      |> Enum.map(&String.trim/1)

    [amount, unit, ingredient] =
      terms
      |> String.split(" ")
      |> Enum.map(&String.downcase/1)
      |> Enum.map(&Inflex.singularize/1)
      |> parse_terms(units)

    {:ok, [amount, unit, Enum.join(ingredient, " "), note]}
  end

  def get_units() do
    Relaxir.Units.list_units
    |> Enum.flat_map(fn u -> [u.name, u.abbreviation] end)
    |> Enum.reject(& &1 == nil)
  end

  defp parse_terms(unmatched, units) do
    {amount, rest} =
      unmatched
      |> hd
      |> Float.parse
      |> parse_float(unmatched)

    [unit | ingredients] = parse_unit(rest, units)

    [amount, unit, ingredients]
  end

  defp parse_float(:error, unmatched), do: {"", unmatched}
  defp parse_float({number, _rest}, [_amount | unmatched]), do: {number, unmatched}

  defp parse_unit([], _units), do: ["", ""]
  defp parse_unit([first | rest], units) do
    if first in units do
      [first | rest]
    else
      ["", first | rest]
    end
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
