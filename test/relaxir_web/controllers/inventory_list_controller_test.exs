defmodule RelaxirWeb.InventoryListControllerTest do
  use RelaxirWeb.ConnCase

  @moduletag :skip

  alias Relaxir.InventoryLists

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup context do
    register_and_log_in_user(context, %{is_admin: true})
  end

  def fixture(:inventory_list) do
    {:ok, inventory_list} = InventoryLists.create_inventory_list(Map.put(@create_attrs, :user_id, 1))
    inventory_list
  end

  describe "index" do
    test "lists all inventory_lists", %{conn: conn} do
      conn = get(conn, Routes.inventory_list_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Inventory lists"
    end
  end

  describe "new inventory_list" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.inventory_list_path(conn, :new))
      assert html_response(conn, 200) =~ "New Inventory list"
    end
  end

  describe "create inventory_list" do
    test "redirects to show when data is valid", %{conn: conn} do
      create = post(conn, Routes.inventory_list_path(conn, :create), inventory_list: @create_attrs)

      assert %{id: id} = redirected_params(create)
      assert redirected_to(create) == Routes.inventory_list_path(create, :show, id)

      conn = get(conn, Routes.inventory_list_path(conn, :show, id))
      assert html_response(conn, 200) =~ @create_attrs.name
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.inventory_list_path(conn, :create), inventory_list: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Inventory list"
    end
  end

  describe "edit inventory_list" do
    setup [:create_inventory_list]

    test "renders form for editing chosen inventory_list", %{conn: conn, inventory_list: inventory_list} do
      conn = get(conn, Routes.inventory_list_path(conn, :edit, inventory_list))
      assert html_response(conn, 200) =~ "Edit Inventory list"
    end
  end

  describe "update inventory_list" do
    setup [:create_inventory_list]

    test "redirects when data is valid", %{conn: conn, inventory_list: inventory_list} do
      create = put(conn, Routes.inventory_list_path(conn, :update, inventory_list), inventory_list: @update_attrs)
      assert redirected_to(create) == Routes.inventory_list_path(create, :show, inventory_list)

      conn = get(conn, Routes.inventory_list_path(conn, :show, inventory_list))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, inventory_list: inventory_list} do
      conn = put(conn, Routes.inventory_list_path(conn, :update, inventory_list), inventory_list: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Inventory list"
    end
  end

  describe "delete inventory_list" do
    setup [:create_inventory_list]

    test "deletes chosen inventory_list", %{conn: conn, inventory_list: inventory_list} do
      create = delete(conn, Routes.inventory_list_path(conn, :delete, inventory_list))
      assert redirected_to(create) == Routes.inventory_list_path(create, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.inventory_list_path(conn, :show, inventory_list))
      end
    end
  end

  describe "add an ingredient to a list" do
    setup [:create_inventory_list, :ingredient]

    test "adds an ingredient to the list", %{conn: conn, inventory_list: inventory_list, ingredient: ingredient} do
      create = post(conn, Routes.inventory_list_path(conn, :add_ingredient, inventory_list.id, ingredient.id))

      assert %{id: id} = redirected_params(create)
      assert redirected_to(create) == Routes.inventory_list_path(create, :show, id)

      show = get(conn, Routes.inventory_list_path(conn, :show, id))
      assert html_response(show, 200) =~ ingredient.name
    end

    test "shows a list selection when adding an ingredient", %{conn: conn, inventory_list: inventory_list} do
      InventoryLists.create_inventory_list(%{name: "extra list", user_id: 1})
      conn = get(conn, Routes.ingredient_path(conn, :select_list, inventory_list))
      assert html_response(conn, 200) =~ inventory_list.name
    end
  end

  describe "remove an ingredient from a list" do
    setup [:ingredient]

    test "removes a ingredient from the list", %{conn: conn, ingredient: ingredient} do
      {:ok, inventory_list} =
        @create_attrs
        |> Map.merge(%{user_id: 1, ingredient_inventory_lists: [%{ingredient_id: ingredient.id}]})
        |> InventoryLists.create_inventory_list()

      assert hd(inventory_list.ingredients).name == ingredient.name

      delete = delete(conn, Routes.inventory_list_path(conn, :remove_ingredient, inventory_list.id, ingredient.id))

      assert %{id: id} = redirected_params(delete)
      assert redirected_to(delete) == Routes.inventory_list_path(delete, :show, id)

      show = get(conn, Routes.inventory_list_path(conn, :show, id))
      assert !(html_response(show, 200) =~ ingredient.name)
    end
  end

  defp create_inventory_list(_) do
    inventory_list = fixture(:inventory_list)
    %{inventory_list: inventory_list}
  end
end
