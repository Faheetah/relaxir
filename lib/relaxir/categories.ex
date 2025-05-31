defmodule Relaxir.Categories do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Categories.Category
  alias Relaxir.RecipeCategory
  alias Relaxir.Recipes.Recipe

  def list_categories do
    Repo.all(
      from c in Category,
      join: rc in RecipeCategory,
      on: rc.category_id == c.id,
      select: [c, count(rc.category_id)],
      where: rc.category_id > 0,
      group_by: c.id,
      order_by: [asc: [c.name]]
    )
    |> Enum.map(fn [category, _count] -> category end)
  end

  def search_categories(name) do
    sanitized = Regex.replace(~r/([\%_])/, name, "\1")
    query = sanitized <> "%"
    Repo.all(from c in Category, where: ilike(c.name, ^query), select: c.name)
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
    query =
      from c in Category,
      where: c.id == ^id,
      join: rc in RecipeCategory,
      on: rc.category_id == c.id,
      join: r in Recipe,
      on: rc.recipe_id == r.id,
      group_by: c.id,
      select: c

    Repo.one(query)
    |> Repo.preload(recipes: [:categories])
  end

  def get_category_by_name!(name) do
    query =
      from c in Category,
      where: c.name == ^name,
      join: rc in RecipeCategory,
      on: rc.category_id == c.id,
      join: r in Recipe,
      on: rc.recipe_id == r.id,
      group_by: c.id,
      select: c

    Repo.one(query)
    |> Repo.preload(recipes: [:categories])
  end

  def reject_unpublished_recipes(%{recipes: recipes, recipe_categories: recipe_categories} = category) do
    filtered_recipe_categories = Enum.reject(recipe_categories, & &1.recipe.published == false)
    filtered_recipes = Enum.reject(recipes, & &1.published == false)

    category
    |> Map.put(:recipe_categories, filtered_recipe_categories)
    |> Map.put(:recipes, filtered_recipes)
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
  end

  def update_image_filename(category, image_filename) do
    update_category(category, %{"image_filename" => image_filename})
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end
