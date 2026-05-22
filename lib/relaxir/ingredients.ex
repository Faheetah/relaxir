defmodule Relaxir.Ingredients do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.Recipes.Recipe
  alias Relaxir.RecipeIngredient

  # these ingredients are too common but insignificant, so we will exclude them
  @excluded_ingredient_names ["salt", "pepper", "oil"]

  def list_ingredients() do
    Ingredient
    |> preload([[parent_ingredient: :parent_ingredient, child_ingredients: :child_ingredients]])
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @doc """
  Returns a map of ingredient_id => [recipes] for the given ingredient IDs.
  Returns up to `limit` random published recipes per ingredient.
  """
  def get_recipes_for_ingredients(ingredient_ids, limit \\ 4) do
    from(
      ri in RecipeIngredient,
      where: ri.ingredient_id in ^ingredient_ids,
      join: r in Recipe,
      on: r.id == ri.recipe_id,
      where: r.published == true,
      select: {ri.ingredient_id, r},
      distinct: [ri.ingredient_id, r.id],
      order_by: fragment("RANDOM()"),
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.group_by(fn {id, _recipe} -> id end, fn {_id, recipe} -> recipe end)
  end

  def list_ingredients_missing_parent() do
    query =
      from i in Ingredient,
        where: is_nil(i.parent_ingredient_id),
        preload: [[parent_ingredient: :parent_ingredient, child_ingredients: :child_ingredients]],
        order_by: [asc: :name]

    Repo.all(query)
  end

  def list_pure_ingredients() do
    query =
      from i in Ingredient,
        where: is_nil(i.parent_ingredient_id),
        where:
          fragment(
            "NOT EXISTS (SELECT 1 FROM recipe_ingredients WHERE ingredient_id = ?)",
            i.id
          ),
        preload: [[parent_ingredient: :parent_ingredient, child_ingredients: :child_ingredients]],
        order_by: [asc: :name]

    Repo.all(query)
  end

  def list_ingredients_missing_singular() do
    query =
      from i in Ingredient,
        where: is_nil(i.singular),
        preload: [[parent_ingredient: :parent_ingredient, child_ingredients: :child_ingredients]],
        order_by: [asc: :name]

    Repo.all(query)
  end

  def top_ingredients(limit \\ 4) do
    recipe_count =
      from ri in RecipeIngredient,
        group_by: ri.ingredient_id,
        select: ri.ingredient_id,
        order_by: [desc: count(ri.recipe_id)],
        limit: ^limit

    query =
      from i in Ingredient,
        where: i.name not in @excluded_ingredient_names,
        join: ri in subquery(recipe_count),
        on: i.id == ri.ingredient_id

    query
    |> preload([[child_ingredients: :child_ingredients]])
    |> Repo.all()
    |> Enum.reverse()
    |> Enum.reduce([], fn ingredient, acc ->
      recipes = get_recipes_for_ingredient(ingredient)

      [{ingredient, recipes} | acc]
    end)
  end

  def get_recipes_for_ingredient(ingredient) do
    children =
      ingredient.child_ingredients
      |> Enum.flat_map(fn i -> [i] ++ i.child_ingredients end)
      |> Enum.map(fn i -> i.id end)

    ingredient_ids = [ingredient.id] ++ children

    top_recipes =
      from ri in RecipeIngredient,
        where: ri.ingredient_id in ^ingredient_ids,
        join: r in Recipe,
        on: r.id == ri.recipe_id,
        where: r.id == ri.recipe_id and r.published == true,
        order_by: [desc: r.inserted_at],
        select: r,
        distinct: r

    top_recipes
    |> Repo.all()
    |> Repo.preload(:user)
    |> Repo.preload(:categories)
  end

  def get_ingredient!(id) do
    preloads = [
      :recipes,
      :source_recipe,
      [
        parent_ingredient: :parent_ingredient,
        child_ingredients: :child_ingredients
      ]
    ]

    Ingredient
    |> preload(^preloads)
    |> Repo.get!(id)
  end

  # We only expecet there to ever be 3 levels of ingredients and not arbitrary levels
  def get_ingredient_by_name!(name) do
    Ingredient
    |> preload(parent_ingredient: :parent_ingredient)
    |> Repo.get_by(name: name)
  end

  # Non-bang version that returns nil instead of raising
  def get_ingredient_by_name(name) do
    Ingredient
    |> preload(parent_ingredient: :parent_ingredient)
    |> Repo.get_by(name: name)
  end

  def get_ingredients_by_name!(names) do
    singular_names = Enum.map(names, &Inflex.singularize/1)

    query =
      from ingredient in Ingredient,
        where: ingredient.name in ^singular_names,
        or_where: ingredient.singular in ^singular_names,
        or_where: ingredient.name in ^names,
        select: ingredient

    Repo.all(query)
  end

  def create_ingredient(attrs) do
    %Ingredient{}
    |> Ingredient.changeset(maybe_singularize_attrs(attrs))
    |> Repo.insert()
  end

  def maybe_singularize_attrs(%{"singular" => ""} = attrs), do: Map.put(attrs, "singular", Inflex.singularize(attrs["name"]))
  def maybe_singularize_attrs(attrs), do: attrs

  def update_image_filename(ingredient, image_filename) do
    update_ingredient(ingredient, %{"image_filename" => image_filename})
  end

  def update_ingredient(%Ingredient{} = ingredient, attrs) do
    ingredient
    |> Ingredient.changeset(attrs)
    |> Repo.update()
  end

  def delete_ingredient(%Ingredient{} = ingredient) do
    Repo.delete(ingredient)
  end

  def change_ingredient(%Ingredient{} = ingredient, attrs \\ %{}) do
    Ingredient.changeset(ingredient, attrs)
  end

  @doc """
  Search for ingredients by name prefix (for live_select autocomplete)
  """
  def search_ingredients(query) when is_binary(query) do
    query =
      from i in Ingredient,
        where: ilike(i.name, ^"#{query}%"),
        order_by: [asc: i.name],
        limit: 20

    Repo.all(query)
    |> Enum.map(& &1.name)
  end

  def search_ingredients(_), do: []

  @doc """
  Search for ingredients by substring (fuzzy match) for suggestion purposes.
  Returns full Ingredient structs so we can use their names.
  """
  def search_ingredients_fuzzy(query) when is_binary(query) and byte_size(query) > 0 do
    search_term = "%#{query}%"

    from(
      i in Ingredient,
      where: ilike(i.name, ^search_term),
      order_by: [asc: i.name],
      limit: 8
    )
    |> Repo.all()
  end

  def search_ingredients_fuzzy(_), do: []
end
