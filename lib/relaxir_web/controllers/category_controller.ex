defmodule RelaxirWeb.CategoryController do
  use RelaxirWeb, :controller

  alias Relaxir.Categories
  alias Relaxir.Categories.Category

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    top_categories = Categories.top_categories()
    render(conn, "index.html", top_categories: top_categories, current_user: current_user)
  end

  def all(conn, _params) do
    current_user = conn.assigns.current_user
    categories = Categories.list_categories()
    render(conn, "all.html", categories: categories, current_user: current_user)
  end

  def new(conn, _params) do
    changeset = Categories.change_category(%Category{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"category" => category_params}) do
    case Categories.create_category(category_params) do
      {:ok, category} ->
        conn
        |> put_flash(:info, "Category created successfully.")
        |> redirect(to: Routes.category_path(conn, :show, category))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"name" => name}) do
    current_user = conn.assigns.current_user
    category = Categories.get_category_by_name!(name)
    recipes = Categories.latest_recipes_for_category(category, 20)
    render(conn, "show.html", category: category, recipes: recipes, current_user: current_user)
  end

  def edit(conn, %{"id" => id}) do
    category = Categories.get_category!(id)
    changeset = Categories.change_category(category)
    render(conn, "edit.html", category: category, changeset: changeset)
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    category = Categories.get_category!(id)

    case Categories.update_category(category, category_params) do
      {:ok, category} ->
        conn
        |> put_flash(:info, "Category updated successfully.")
        |> redirect(to: Routes.category_path(conn, :show, category))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", category: category, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    category = Categories.get_category!(id)
    {:ok, _category} = Categories.delete_category(category)

    conn
    |> put_flash(:info, "Category deleted successfully.")
    |> redirect(to: Routes.category_path(conn, :index))
  end
end
