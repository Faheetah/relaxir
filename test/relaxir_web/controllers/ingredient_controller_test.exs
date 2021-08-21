defmodule RelaxirWeb.IngredientControllerTest do
  use RelaxirWeb.ConnCase

  setup context do
    register_and_log_in_user(context, %{admin: true})
  end

  describe "index" do
    test "lists all ingredients", %{conn: conn} do
      conn = get(conn, Routes.ingredient_path(conn, :index))
      assert html_response(conn, 200) =~ "Ingredients"
    end
  end

  describe "new ingredient" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.ingredient_path(conn, :new))
      assert html_response(conn, 200) =~ "New Ingredient"
    end
  end

  describe "create ingredient" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn =
        post(conn, Routes.ingredient_path(conn, :create), ingredient: %{name: "ingredient fixture", description: "description fixture"})

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.ingredient_path(conn, :show, id)

      conn = get(conn, Routes.ingredient_path(conn, :show, id))
      response = html_response(conn, 200)
      assert response =~ "Ingredient fixture"
      assert response =~ "description fixture"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.ingredient_path(conn, :create), ingredient: %{name: nil})
      assert html_response(conn, 200) =~ "New Ingredient"
    end
  end

  describe "edit ingredient" do
    setup [:ingredient]

    test "renders form for editing chosen ingredient", %{conn: conn, ingredient: ingredient} do
      conn = get(conn, Routes.ingredient_path(conn, :edit, ingredient))
      assert html_response(conn, 200) =~ "Edit Ingredient"
    end
  end

  describe "update ingredient" do
    setup [:ingredient]

    test "redirects when data is valid", %{conn: conn, ingredient: ingredient} do
      conn = put(conn, Routes.ingredient_path(conn, :update, ingredient), ingredient: %{name: "some updated name"})

      assert redirected_to(conn) == Routes.ingredient_path(conn, :show, ingredient)

      conn = get(conn, Routes.ingredient_path(conn, :show, ingredient))
      assert html_response(conn, 200) =~ "Some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, ingredient: ingredient} do
      conn = put(conn, Routes.ingredient_path(conn, :update, ingredient), ingredient: %{name: nil})

      assert html_response(conn, 200) =~ "Edit Ingredient"
    end
  end

  describe "delete ingredient" do
    setup [:ingredient]

    test "deletes chosen ingredient", %{conn: conn, ingredient: ingredient} do
      conn = delete(conn, Routes.ingredient_path(conn, :delete, ingredient))
      assert redirected_to(conn) == Routes.ingredient_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.ingredient_path(conn, :show, ingredient))
      end
    end
  end
end
