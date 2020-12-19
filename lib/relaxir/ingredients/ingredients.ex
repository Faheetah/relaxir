defmodule Relaxir.Ingredients do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Ingredients.Ingredient

  def list_ingredients do
    Repo.all(order_by(Ingredient, asc: :name))
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
    now = NaiveDateTime.utc_now |> NaiveDateTime.truncate(:second)
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
    Relaxir.Search.set(Relaxir.Ingredients.Ingredient, :name, {ingredient.name, [ingredient.name, ingredient.id]})
  end

  def delete_cache(ingredient) do
    Relaxir.Search.delete(Relaxir.Ingredients.Ingredient, :name, {ingredient.name, [ingredient.name, ingredient.id]})
  end
end
