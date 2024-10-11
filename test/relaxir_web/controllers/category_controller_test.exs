defmodule RelaxirWeb.CategoryControllerTest do
  use RelaxirWeb.ConnCase

  alias Relaxir.Categories

  @moduletag :skip

  @create_attrs %{name: "some name"}

  setup context do
    register_and_log_in_user(context, %{is_admin: true})
  end

  def fixture(:category) do
    {:ok, category} = Categories.create_category(@create_attrs)
    category
  end

  describe "index" do
    test "lists all categories", %{conn: conn} do
      conn = get(conn, Routes.category_path(conn, :index))
      assert html_response(conn, 200) =~ "Categories"
    end
  end
end
