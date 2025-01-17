defmodule Relaxir.Categories do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Categories.Category
  alias Relaxir.RecipeCategory
  alias Relaxir.Recipes.Recipe

  def list_categories do
    Repo.all(order_by(Category, asc: :name))
  end

  def top_categories(category_limit \\ 8, recipe_limit \\ 4) do
    Repo.all(
      from c in Category,
      join: rc in RecipeCategory,
      on: rc.category_id == c.id,
      group_by: c.id,
      order_by: [desc: count(rc.recipe_id)],
      limit: ^category_limit
    )
    |> Enum.map(fn category ->
      Map.put(category, :recipes, latest_recipes_for_category(category, recipe_limit))
    end)
  end

  def latest_recipes_for_category(category, limit \\ 4) do
    top_recipes =
      from rc in RecipeCategory,
      where: rc.category_id == ^category.id,
      join: r in Recipe, on: r.id == rc.recipe_id,
      where: r.id == rc.recipe_id,
      where: r.published == true,
      order_by: [desc: r.inserted_at],
      select: r,
      limit: ^limit

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
    |> Repo.preload(recipes: [:categories])
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
