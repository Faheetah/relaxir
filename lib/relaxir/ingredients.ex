defmodule Relaxir.Ingredients do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.Ingredients.Unit

  def list_ingredients do
    Repo.all(order_by(Ingredient, asc: :name))
  end

  def get_ingredient!(id) do
    Ingredient
    |> preload(:recipes)
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
  end

  def create_ingredients(attrs) do
    now = NaiveDateTime.utc_now |> NaiveDateTime.truncate(:second)
    timestamps = %{inserted_at: now, updated_at: now}
    Repo.insert_all(Ingredient, Enum.map(attrs, &Map.merge(&1, timestamps)))
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

  def create_unit(attrs) do
    %Unit{}
    |> Unit.changeset(attrs)
    |> Repo.insert()
  end

  def delete_unit(%Unit{} = unit) do
    Repo.delete(unit)
  end

  def list_units() do
    Repo.all(Unit)
  end
end
