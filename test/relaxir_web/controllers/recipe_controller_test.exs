defmodule RelaxirWeb.RecipeControllerTest do
  use RelaxirWeb.ConnCase

  alias Relaxir.Recipes

  @create_attrs %{
    "directions" => "some directions",
    "title" => "some title",
    "categories" => "",
    "ingredients" => ""
  }
  @update_attrs %{
    "directions" => "updated directions",
    "title" => "updated title",
    "categories" => "",
    "ingredients" => ""
  }
  @invalid_attrs %{"directions" => nil, "title" => nil, "ingredients" => "", "categories" => ""}
  @defaults %{"categories" => [], "ingredients" => []}
  @ingredients %{"ingredients" => "cauliflower\nbroccoli"}
  @ingredients_with_amounts %{"ingredients" => "2 cups flour\negg, hard boiled"}
  @categories %{"categories" => "texmex, breakfast"}

  def create_recipe_with_associations(_) do
    ingredients = [%{name: "cauliflower"}, %{name: "broccoli"}]
    categories = ["texmex", "breakfast"]

    {:ok, recipe} =
      @create_attrs
      |> Map.merge(@defaults)
      |> Map.merge(%{"ingredients" => ingredients})
      |> Map.merge(%{"categories" => categories})
      |> Recipes.create_recipe()

    %{recipe: recipe}
  end

  def create_recipe(_) do
    {:ok, recipe} =
      @create_attrs
      |> Map.merge(@defaults)
      |> Recipes.create_recipe()

    %{recipe: recipe}
  end

  describe "index" do
    test "lists all recipes", %{conn: conn} do
      conn = get(conn, Routes.recipe_path(conn, :index))
      assert html_response(conn, 200) =~ "Recipes"
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
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ "some directions"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: @invalid_attrs)
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

    test "updates existing ingredients", %{conn: conn, recipe_with_ingredients: recipe} do
      conn = put(conn, Routes.recipe_path(conn, :update, recipe), recipe: Map.merge(@update_attrs, @ingredients))

      assert redirected_to(conn) == Routes.recipe_path(conn, :show, recipe)

      conn = get(conn, Routes.recipe_path(conn, :show, recipe))
      assert html_response(conn, 200) =~ "broccoli"
    end
  end

  describe "update recipe" do
    setup [:recipe]

    test "redirects when data is valid", %{conn: conn, recipe: recipe} do
      conn = put(conn, Routes.recipe_path(conn, :update, recipe), recipe: @update_attrs)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, recipe)

      conn = get(conn, Routes.recipe_path(conn, :show, recipe))
      assert html_response(conn, 200) =~ "updated directions"
    end

    test "renders errors when data is invalid", %{conn: conn, recipe: recipe} do
      conn = put(conn, Routes.recipe_path(conn, :update, recipe), recipe: @invalid_attrs)
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
    test "adds ingredients from string", %{conn: conn} do
      create_attrs = Map.merge(@create_attrs, @ingredients)
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ "cauliflower"
      assert html_response(conn, 200) =~ "broccoli"
    end

    test "adds ingredients with amounts and notes from string", %{conn: conn} do
      create_attrs = Map.merge(@create_attrs, @ingredients_with_amounts)
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ "2 cups flour"
      assert html_response(conn, 200) =~ "egg, hard boiled"
    end

    test "adds existing ingredients with amounts and notes from string", %{conn: conn} do
      create_recipe_with_associations(%{})

      create_attrs = Map.merge(@update_attrs, %{"ingredients" => "1 cup broccoli, diced"})
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ "1 cup broccoli, diced"
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
      create_attrs = Map.merge(@create_attrs, @categories)
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.recipe_path(conn, :show, id)

      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ "texmex"
      assert html_response(conn, 200) =~ "breakfast"
    end
  end

  describe "rendering categories" do
    setup [:recipe_with_categories, :category]

    test "renders categories from list", %{conn: conn, recipe_with_categories: recipe} do
      conn = get(conn, Routes.recipe_path(conn, :edit, recipe))
      response = html_response(conn, 200)

      recipe.fixture["categories"]
      |> Enum.each(&(assert response =~ &1))
    end

    test "uses an existing category", %{conn: conn, category: category} do
      conn = post(conn, Routes.recipe_path(conn, :create), recipe: %{"title" => "_", "categories" => category.name})

      %{id: id} = redirected_params(conn)
      conn = get(conn, Routes.recipe_path(conn, :show, id))
      assert html_response(conn, 200) =~ category.name
    end
  end
end
