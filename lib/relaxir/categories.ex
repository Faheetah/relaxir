defmodule Relaxir.Categories do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Categories.Category

  def list_categories do
    Repo.all(order_by(Category, asc: :name))
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
        try do
          Relaxir.Search.set(Relaxir.Categories.Category, :name, category.name)
        catch
          :exit, _ -> nil
        end
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
      try do
        Relaxir.Search.delete(Relaxir.Categories.Category, :name, category.name)
        Relaxir.Search.set(Relaxir.Categories.Category, :name, name)
      catch
        :exit, _ -> nil
      end
    end
    changeset
  end

  def delete_category(%Category{} = category) do
    try do
      Relaxir.Search.delete(Relaxir.Categories.Category, :name, category.name)
    catch
      :exit, _ -> nil
    end
    Repo.delete(category)
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end
