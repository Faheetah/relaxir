defmodule RelaxirWeb.RecipeControllerTest do
  use RelaxirWeb.ConnCase

  setup context do
    register_and_log_in_user(context, %{is_admin: true})
  end

  describe "index" do
    setup [:recipe_draft, :recipe_published, :recipes]

    test "lists all recipes", %{conn: conn, recipes: recipes} do
      conn = get(conn, Routes.recipe_path(conn, :index, show: "all"))
      response = html_response(conn, 200)
      assert response =~ recipes.recipe_published["title"]
      assert response =~ recipes.recipe_draft["title"]
    end

    test "lists only published recipes", %{conn: conn, recipes: recipes} do
      conn = get(conn, Routes.recipe_path(conn, :index, show: "published"))
      response = html_response(conn, 200)
      assert response =~ recipes.recipe_published["title"]
      refute response =~ recipes.recipe_draft["title"]
    end

    test "lists only draft recipes", %{conn: conn, recipes: recipes} do
      conn = get(conn, Routes.recipe_path(conn, :index, show: "drafts"))
      response = html_response(conn, 200)
      refute response =~ recipes.recipe_published["title"]
      assert response =~ recipes.recipe_draft["title"]
    end
  end

  describe "new recipe" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.recipe_path(conn, :new))
      assert html_response(conn, 200) =~ "New Recipe"
    end
  end

  describe "create recipe" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: %{"title" => "_", "directions" => "some directions"})

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ "some directions"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: %{"title" => nil})
      assert html_response(conn, 200) =~ "New Recipe"
    end
  end

  describe "edit recipe" do
    setup [:recipe]

    test "renders form for editing chosen recipe", %{conn: conn, recipe: recipe} do
      conn = get(conn, Routes.recipe_path(conn, :edit, recipe))
      assert html_response(conn, 200) =~ "Edit Recipe"
    end
  end

  describe "update recipe with ingredients" do
    setup [:recipe_with_ingredients]

    test "retains existing ingredients", %{conn: conn, recipe_with_ingredients: recipe} do
      ingredients =
        recipe.fixture["ingredients"]
        |> Enum.map(fn i -> i.name end)
        |> Enum.join("\n")

      conn = put(conn, Routes.recipe_path(conn, :update, recipe), recipe: %{ingredients: ingredients})

      assert redirected_to(conn) == Routes.recipe_path(conn, :show, recipe)

      conn = get(conn, Routes.recipe_path(conn, :show, recipe))
      response = html_response(conn, 200)

      recipe.fixture["ingredients"]
      |> Enum.each(fn i -> assert response =~ i.name end)
    end
  end

  describe "update recipe" do
    setup [:recipe]

    test "redirects when data is valid", %{conn: conn, recipe: recipe} do
      conn = put(conn, Routes.recipe_path(conn, :update, recipe), recipe: %{directions: "updated directions"})
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, recipe)

      conn = get(conn, Routes.recipe_path(conn, :show, recipe))
      assert html_response(conn, 200) =~ "updated directions"
    end

    test "renders errors when data is invalid", %{conn: conn, recipe: recipe} do
      conn = put(conn, Routes.recipe_path(conn, :update, recipe), recipe: %{title: nil})
      assert html_response(conn, 200) =~ "Edit Recipe"
    end
  end

  describe "delete recipe" do
    setup [:recipe]

    test "deletes chosen recipe", %{conn: conn, recipe: recipe} do
      conn = delete(conn, Routes.recipe_path(conn, :delete, recipe))
      assert redirected_to(conn) == Routes.recipe_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.recipe_path(conn, :show, recipe))
      end
    end
  end

  describe "creating ingredients" do
    setup [:ingredient]

    test "adds ingredients with amounts and notes from string", %{conn: conn} do
      attrs = %{title: "_", ingredients: "1 cup new ingredient, diced"}
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ attrs.ingredients
    end

    test "adds existing ingredients with amounts and notes from string", %{conn: conn, ingredient: ingredient} do
      attrs = %{title: "_", ingredients: "1 cup #{ingredient.name}, diced"}
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ "1 cup #{ingredient.name}, diced"
    end

    test "creates an ingredient without a unit", %{conn: conn, ingredient: ingredient} do
      attrs = %{title: "_", ingredients: "1 #{ingredient.name}, diced"}
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ "1 #{ingredient.name}, diced"
    end
  end

  describe "rendering ingredients" do
    setup [:ingredient, :recipe_with_ingredients]

    test "renders ingredients from list", %{conn: conn, recipe_with_ingredients: recipe} do
      conn = get(conn, Routes.recipe_path(conn, :edit, recipe))
      response = html_response(conn, 200)

      recipe.fixture["ingredients"]
      |> Enum.each(fn i -> assert response =~ i.name end)
    end

    test "uses an existing ingredient", %{conn: conn, ingredient: ingredient} do
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: %{"title" => "_", "ingredients" => ingredient.name})

      %{id: id} = redirected_params(conn)
      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ ingredient.name
    end
  end

  describe "categories" do
    test "adds categories from string", %{conn: conn} do
      attrs = %{title: "_", categories: "category1, category2"}
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      response = html_response(conn, 200)

      ["category1", "category2"]
      |> Enum.each(&assert response =~ &1)
    end
  end

  describe "rendering categories" do
    setup [:recipe_with_categories, :category]

    test "renders categories from list", %{conn: conn, recipe_with_categories: recipe} do
      conn = get(conn, Routes.recipe_path(conn, :edit, recipe))
      response = html_response(conn, 200)

      recipe.fixture["categories"]
      |> Enum.each(&assert response =~ &1)
    end

    test "uses an existing category", %{conn: conn, category: category} do
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: %{"title" => "_", "categories" => category.name})

      %{id: id} = redirected_params(conn)
      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ String.upcase(category.name)
    end
  end
end
