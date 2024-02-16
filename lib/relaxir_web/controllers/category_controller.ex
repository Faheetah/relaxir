defmodule RelaxirWeb.CategoryController do
  use RelaxirWeb, :controller

  alias Relaxir.Categories

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

  def show(conn, %{"name" => name}) do
    current_user = conn.assigns.current_user
    category = Categories.get_category_by_name!(name)
    recipes = Categories.latest_recipes_for_category(category, 20)
    render(conn, "show.html", category: category, recipes: recipes, current_user: current_user)
  end
end
