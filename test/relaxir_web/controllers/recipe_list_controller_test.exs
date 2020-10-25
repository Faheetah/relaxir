defmodule RelaxirWeb.RecipeListControllerTest do
  use RelaxirWeb.ConnCase

  alias Relaxir.RecipeLists

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:recipe_list) do
    {:ok, recipe_list} = RecipeLists.create_recipe_list(Map.put(@create_attrs, :user_id, 1))
    recipe_list
  end

  describe "index" do
    test "lists all recipe_list", %{conn: conn} do
      conn = get(conn, Routes.recipe_list_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Recipe list"
    end
  end

  describe "new recipe_list" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.recipe_list_path(conn, :new))
      assert html_response(conn, 200) =~ "New Recipe list"
    end
  end

  describe "create recipe_list" do
    test "redirects to show when data is valid", %{conn: conn} do
      create = post(conn, Routes.recipe_list_path(conn, :create), recipe_list: @create_attrs)

      assert %{id: id} = redirected_params(create)
      assert redirected_to(create) == Routes.recipe_list_path(create, :show, id)

      show = get(conn, Routes.recipe_list_path(conn, :show, id))
      assert html_response(show, 200) =~ @create_attrs.name
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.recipe_list_path(conn, :create), recipe_list: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Recipe list"
    end
  end

  describe "edit recipe_list" do
    setup [:create_recipe_list]

    test "renders form for editing chosen recipe_list", %{conn: conn, recipe_list: recipe_list} do
      conn = get(conn, Routes.recipe_list_path(conn, :edit, recipe_list))
      assert html_response(conn, 200) =~ "Edit Recipe list"
    end
  end

  describe "update recipe_list" do
    setup [:create_recipe_list]

    test "redirects when data is valid", %{conn: conn, recipe_list: recipe_list} do
      create = put(conn, Routes.recipe_list_path(conn, :update, recipe_list), recipe_list: @update_attrs)

      assert redirected_to(create) == Routes.recipe_list_path(create, :show, recipe_list)

      conn = get(conn, Routes.recipe_list_path(conn, :show, recipe_list))
      assert html_response(conn, 200) =~ @update_attrs.name
    end

    test "renders errors when data is invalid", %{conn: conn, recipe_list: recipe_list} do
      conn = put(conn, Routes.recipe_list_path(conn, :update, recipe_list), recipe_list: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Recipe list"
    end
  end

  describe "delete recipe_list" do
    setup [:create_recipe_list]

    test "deletes chosen recipe_list", %{conn: conn, recipe_list: recipe_list} do
      create = delete(conn, Routes.recipe_list_path(conn, :delete, recipe_list))
      assert redirected_to(create) == Routes.recipe_list_path(create, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.recipe_list_path(conn, :show, recipe_list))
      end
    end
  end

  describe "add a recipe to a list" do
    setup [:create_recipe_list, :recipe]

    test "adds a recipe to the list", %{conn: conn, recipe_list: recipe_list, recipe: recipe} do
      create = post(conn, Routes.recipe_list_path(conn, :add_recipe, recipe_list.id, recipe.id))

      assert %{id: id} = redirected_params(create)
      assert redirected_to(create) == Routes.recipe_list_path(create, :show, id)

      show = get(conn, Routes.recipe_list_path(conn, :show, id))
      assert html_response(show, 200) =~ recipe.title
    end

    test "shows a list selection when adding a recipe", %{conn: conn, recipe_list: recipe_list} do
      conn = get(conn, Routes.recipe_list_path(conn, :select_list, recipe_list))
      assert html_response(conn, 200) =~ recipe_list.name
    end
  end

  describe "remove a recipe from a list" do
    setup [:recipe]

    test "removes a recipe from the list", %{conn: conn, recipe: recipe} do
      {:ok, recipe_list} =
        @create_attrs
        |> Map.merge(%{user_id: 1, recipe_recipe_lists: [%{recipe_id: recipe.id}]})
        |> RecipeLists.create_recipe_list()
      assert hd(recipe_list.recipes).title == recipe.title

      delete = delete(conn, Routes.recipe_list_path(conn, :remove_recipe, recipe_list.id, recipe.id))

      assert %{id: id} = redirected_params(delete)
      assert redirected_to(delete) == Routes.recipe_list_path(delete, :show, id)

      show = get(conn, Routes.recipe_list_path(conn, :show, id))
      assert !(html_response(show, 200) =~ recipe.title)
    end
  end

  defp create_recipe_list(_) do
    recipe_list = fixture(:recipe_list)
    %{recipe_list: recipe_list}
  end
end
