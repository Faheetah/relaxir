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

  def list_ingredients_missing_parent() do
    query =
      from i in Ingredient,
      where: is_nil(i.parent_ingredient_id),
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
      recipes = latest_recipes_for_ingredient(ingredient)

      [{ingredient, recipes} | acc]
    end)
  end

  def latest_recipes_for_ingredient(ingredient, limit \\ 4) do
    children =
      ingredient.child_ingredients
      |> Enum.flat_map(fn i -> [i] ++ i.child_ingredients end)
      |> Enum.map(fn i -> i.id end)

    ingredient_ids = [ingredient.id] ++ children

    top_recipes =
      from ri in RecipeIngredient,
      where: ri.ingredient_id in ^ingredient_ids,
      join: r in Recipe, on: r.id == ri.recipe_id,
      where: r.id == ri.recipe_id,
      order_by: [desc: r.inserted_at],
      select: r,
      distinct: r,
      limit: ^limit

    top_recipes
    |> Repo.all
    |> Repo.preload(:user)
    |> Repo.preload(:categories)
  end

  def get_ingredient!(id) do
    Ingredient
    |> preload([:recipes, :food, [parent_ingredient: :parent_ingredient, child_ingredients: :child_ingredients]])
    |> Repo.get!(id)
  end

  # We only expecet there to ever be 3 levels of ingredients and not arbitrary levels
  def get_ingredient_by_name!(name) do
    Ingredient
    |> preload([parent_ingredient: :parent_ingredient])
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
    |> case do
      {:ok, ingredient} ->
        insert_cache(ingredient)
        {:ok, ingredient}

      error ->
        error
    end
  end

  def maybe_singularize_attrs(attrs = %{"singular" => ""}), do: Map.put(attrs, "singular", Inflex.singularize(attrs["name"]))
  def maybe_singularize_attrs(attrs), do: attrs

  def update_ingredient(%Ingredient{} = ingredient, attrs) do
    ingredient
    |> Ingredient.changeset(attrs)
    |> do_changeset_update(ingredient)
    |> Repo.update()
  end

  def do_changeset_update(changeset, ingredient) do
    with %{name: name} <- changeset.changes do
      delete_cache(ingredient)
      insert_cache(%{name: name, id: ingredient.id})
    end

    changeset
  end

  def delete_ingredient(%Ingredient{} = ingredient) do
    delete_cache(ingredient)
    Repo.delete(ingredient)
  end

  def change_ingredient(%Ingredient{} = ingredient, attrs \\ %{}) do
    Ingredient.changeset(ingredient, attrs)
  end

  def insert_cache(ingredient) do
    Invert.set(Relaxir.Ingredients.Ingredient, :name, {ingredient.name, [ingredient.name, ingredient.id]})
  end

  def delete_cache(ingredient) do
    Invert.delete(Relaxir.Ingredients.Ingredient, :name, {ingredient.name, [ingredient.name, ingredient.id]})
  end
end
