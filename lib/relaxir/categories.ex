defmodule Relaxir.Categories do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Categories.Category

  def list_categories do
    Repo.all(Category)
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
