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
end
