defmodule Relaxir.Categories do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Categories.Category
  alias Relaxir.RecipeCategory
  alias Relaxir.Recipes.Recipe

  def list_categories do
    Repo.all(order_by(Category, asc: :name))
  end

  def top_categories(limit \\ 4) do
    recipe_count =
      from ri in RecipeCategory,
      group_by: ri.category_id,
      select: ri.category_id,
      order_by: [desc: count(ri.recipe_id)],
      limit: ^limit

    query =
      from i in Category,
      join: ri in subquery(recipe_count),
      on: i.id == ri.category_id

    Repo.all(query)
    |> Enum.reverse()
    |> Enum.reduce([], fn category, acc ->
      recipes = latest_recipes_for_category(category)

      [{category, recipes} | acc]
    end)
  end

  def latest_recipes_for_category(category) do
    top_recipes =
      from rc in RecipeCategory,
      where: rc.category_id == ^category.id,
      join: r in Recipe,
      where: r.id == rc.recipe_id,
      order_by: [desc: r.inserted_at],
      select: r,
      limit: 4

    recipes =
      top_recipes
      |> Repo.all
      |> Repo.preload(:user)
      |> Repo.preload(:categories)
  end


  def get_category!(id) do
    Category
    |> preload(:recipes)
    |> Repo.get!(id)
  end

  def get_category_by_name!(name) do
    Repo.get_by(Category, name: name)
  end

  def get_categories_by_name!(names) do
    query =
      from category in Category,
        where: category.name in ^names,
        select: category

    query
    |> Repo.all()
  end

  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, category} ->
        insert_cache(category)
        {:ok, category}

      error ->
        error
    end
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> do_changeset_update(category)
    |> Repo.update()
  end

  def do_changeset_update(changeset, category) do
    with %{name: name} <- changeset.changes do
      delete_cache(category)
      insert_cache(%{name: name, id: category.id})
    end

    changeset
  end

  def delete_category(%Category{} = category) do
    delete_cache(category)
    Repo.delete(category)
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  def insert_cache(category) do
    Invert.set(Relaxir.Categories.Category, :name, {category.name, [category.name, category.id]})
  end

  def delete_cache(category) do
    Invert.delete(Relaxir.Categories.Category, :name, {category.name, [category.name, category.id]})
  end
end
