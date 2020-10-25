defmodule RelaxirWeb.GroceryListControllerTest do
  use RelaxirWeb.ConnCase

  alias Relaxir.GroceryLists

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:grocery_list) do
    {:ok, grocery_list} = GroceryLists.create_grocery_list(Map.put(@create_attrs, :user_id, 1))
    grocery_list
  end

  describe "index" do
    test "lists all grocery_lists", %{conn: conn} do
      conn = get(conn, Routes.grocery_list_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Grocery lists"
    end
  end

  describe "new grocery_list" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.grocery_list_path(conn, :new))
      assert html_response(conn, 200) =~ "New Grocery list"
    end
  end

  describe "create grocery_list" do
    test "redirects to show when data is valid", %{conn: conn} do
      create = post(conn, Routes.grocery_list_path(conn, :create), grocery_list: @create_attrs)

      assert %{id: id} = redirected_params(create)
      assert redirected_to(create) == Routes.grocery_list_path(create, :show, id)

      conn = get(conn, Routes.grocery_list_path(conn, :show, id))
      assert html_response(conn, 200) =~ @create_attrs.name
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.grocery_list_path(conn, :create), grocery_list: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Grocery list"
    end
  end

  describe "edit grocery_list" do
    setup [:create_grocery_list]

    test "renders form for editing chosen grocery_list", %{conn: conn, grocery_list: grocery_list} do
      conn = get(conn, Routes.grocery_list_path(conn, :edit, grocery_list))
      assert html_response(conn, 200) =~ "Edit Grocery list"
    end
  end

  describe "update grocery_list" do
    setup [:create_grocery_list]

    test "redirects when data is valid", %{conn: conn, grocery_list: grocery_list} do
      create = put(conn, Routes.grocery_list_path(conn, :update, grocery_list), grocery_list: @update_attrs)
      assert redirected_to(create) == Routes.grocery_list_path(create, :show, grocery_list)

      conn = get(conn, Routes.grocery_list_path(conn, :show, grocery_list))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, grocery_list: grocery_list} do
      conn = put(conn, Routes.grocery_list_path(conn, :update, grocery_list), grocery_list: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Grocery list"
    end
  end

  describe "delete grocery_list" do
    setup [:create_grocery_list]

    test "deletes chosen grocery_list", %{conn: conn, grocery_list: grocery_list} do
      create = delete(conn, Routes.grocery_list_path(conn, :delete, grocery_list))
      assert redirected_to(create) == Routes.grocery_list_path(create, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.grocery_list_path(conn, :show, grocery_list))
      end
    end
  end

  describe "add an ingredient to a list" do
    setup [:create_grocery_list, :ingredient]

    test "adds an ingredient to the list", %{conn: conn, grocery_list: grocery_list, ingredient: ingredient} do
      create = post(conn, Routes.grocery_list_path(conn, :add_ingredient, grocery_list.id, ingredient.id))

      assert %{id: id} = redirected_params(create)
      assert redirected_to(create) == Routes.grocery_list_path(create, :show, id)

      show = get(conn, Routes.grocery_list_path(conn, :show, id))
      assert html_response(show, 200) =~ ingredient.name
    end

    test "shows a list selection when adding an ingredient", %{conn: conn, grocery_list: grocery_list} do
      conn = get(conn, Routes.grocery_list_path(conn, :select_list, grocery_list))
      assert html_response(conn, 200) =~ grocery_list.name
    end
  end

  describe "remove an ingredient from a list" do
    setup [:ingredient]

    test "removes a ingredient from the list", %{conn: conn, ingredient: ingredient} do
      {:ok, grocery_list} =
        @create_attrs
        |> Map.merge(%{user_id: 1, ingredient_grocery_lists: [%{ingredient_id: ingredient.id}]})
        |> GroceryLists.create_grocery_list()

      assert hd(grocery_list.ingredients).name == ingredient.name

      delete = delete(conn, Routes.grocery_list_path(conn, :remove_ingredient, grocery_list.id, ingredient.id))

      assert %{id: id} = redirected_params(delete)
      assert redirected_to(delete) == Routes.grocery_list_path(delete, :show, id)

      show = get(conn, Routes.grocery_list_path(conn, :show, id))
      IO.inspect html_response(show, 200)
      assert !(html_response(show, 200) =~ ingredient.name)
    end
  end

  defp create_grocery_list(_) do
    grocery_list = fixture(:grocery_list)
    %{grocery_list: grocery_list}
  end
end
