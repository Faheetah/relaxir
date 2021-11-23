defmodule Relaxir.Ingredients do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.Recipes.Recipe
  alias Relaxir.RecipeIngredient

  def list_ingredients do
    Repo.all(order_by(Ingredient, asc: :name))
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
      join: ri in subquery(recipe_count),
      on: i.id == ri.ingredient_id

    Repo.all(query)
    |> Enum.reverse()
    |> Enum.reduce([], fn ingredient, acc ->
      recipes = latest_recipes_for_ingredient(ingredient)

      [{ingredient, recipes} | acc]
    end)
  end

  def latest_recipes_for_ingredient(ingredient) do
    top_recipes =
      from ri in RecipeIngredient,
      where: ri.ingredient_id == ^ingredient.id,
      join: r in Recipe,
      where: r.id == ri.recipe_id,
      order_by: [desc: r.inserted_at],
      select: r,
      limit: 4

    recipes =
      top_recipes
      |> Repo.all
      |> Repo.preload(:user)
      |> Repo.preload(:categories)
  end

  def get_ingredient!(id) do
    Ingredient
    |> preload([:recipes, :food])
    |> Repo.get!(id)
  end

  def get_ingredient_by_name!(name) do
    Repo.get_by(Ingredient, name: name)
  end

  def get_ingredients_by_name!(names) do
    query =
      from ingredient in Ingredient,
        where: ingredient.name in ^names,
        select: ingredient

    query
    |> Repo.all()
  end

  def create_ingredient(attrs) do
    %Ingredient{}
    |> Ingredient.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, ingredient} ->
        insert_cache(ingredient)
        {:ok, ingredient}

      error ->
        error
    end
  end

  def create_ingredients(attrs) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    timestamps = %{inserted_at: now, updated_at: now}

    Repo.insert_all(Ingredient, Enum.map(attrs, &Map.merge(&1, timestamps)))
    |> Enum.map(fn ingredient ->
      case ingredient do
        {:ok, ingredient} ->
          insert_cache(ingredient)
          {:ok, ingredient}

        error ->
          error
      end
    end)
  end

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
