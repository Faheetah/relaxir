defmodule RelaxirWeb.IngredientController do
  use RelaxirWeb, :controller

  alias Relaxir.Ingredients
  alias Relaxir.Ingredients.Ingredient

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    top_ingredients = Ingredients.top_ingredients()
    render(conn, "index.html", top_ingredients: top_ingredients, current_user: current_user)
  end

  def all(conn, _params) do
    current_user = conn.assigns.current_user
    ingredients = Ingredients.list_ingredients()
    render(conn, "all.html", ingredients: ingredients, current_user: current_user)
  end

  def new(conn, _params) do
    changeset = Ingredients.change_ingredient(%Ingredient{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"ingredient" => ingredient_params, "for" => list_for, "list_id" => list_id}) do
    case Ingredients.create_ingredient(ingredient_params) do
      {:ok, ingredient} ->
        case list_for do
          "groceries" -> RelaxirWeb.GroceryListController.add_ingredient(conn, %{"id" => list_id, "ingredient_id" => ingredient.id})
          "inventories" -> RelaxirWeb.InventoryListController.add_ingredient(conn, %{"id" => list_id, "ingredient_id" => ingredient.id})
          _ -> redirect(conn, to: Routes.ingredient_path(conn, :show, ingredient))
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def create(conn, %{"ingredient" => ingredient_params, "for" => list_for}) do
    case Ingredients.create_ingredient(ingredient_params) do
      {:ok, ingredient} ->
        select_list(conn, %{"ingredient_id" => ingredient.id, "for" => list_for})

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def create(conn, %{"ingredient" => ingredient_params}) do
    ingredient_params = maybe_add_parent_ingredient_id(ingredient_params)

    case Ingredients.create_ingredient(ingredient_params) do
      {:ok, ingredient} ->
        redirect(conn, to: Routes.ingredient_path(conn, :show, ingredient))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  defp maybe_add_parent_ingredient_id(ingredient = %{"parent_ingredient_name" => name}) do
    case Ingredients.get_ingredient_by_name!(name) do
      nil -> ingredient
      %{id: id} -> Map.put(ingredient, "parent_ingredient_id", id)
    end
  end

  defp maybe_add_parent_ingredient_id(ingredient), do: ingredient

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    ingredient = Ingredients.get_ingredient!(id)
    recipes = Ingredients.latest_recipes_for_ingredient(ingredient, 20)
    render(conn, "show.html", ingredient: ingredient, recipes: recipes, current_user: current_user)
  end

  def edit(conn, %{"id" => id}) do
    ingredient = Ingredients.get_ingredient!(id)
    changeset = Ingredients.change_ingredient(ingredient)
    render(conn, "edit.html", ingredient: ingredient, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ingredient" => ingredient_params}) do
    ingredient = Ingredients.get_ingredient!(id)

    ingredient_params = maybe_add_parent_ingredient_id(ingredient_params)

    case Ingredients.update_ingredient(ingredient, ingredient_params) do
      {:ok, ingredient} ->
        conn
        |> put_flash(:info, "Ingredient updated successfully.")
        |> redirect(to: Routes.ingredient_path(conn, :show, ingredient))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", ingredient: ingredient, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    ingredient = Ingredients.get_ingredient!(id)
    {:ok, _ingredient} = Ingredients.delete_ingredient(ingredient)

    conn
    |> put_flash(:info, "Ingredient deleted successfully.")
    |> redirect(to: Routes.ingredient_path(conn, :index))
  end

  def select_list(conn, %{"ingredient_id" => ingredient_id, "for" => list_for}) do
    inventory_lists = Relaxir.InventoryLists.list_inventory_lists()
    grocery_lists = Relaxir.GroceryLists.list_grocery_lists()

    cond do
      length(inventory_lists) == 1 && Enum.empty?(grocery_lists) ->
        RelaxirWeb.InventoryListController.add_ingredient(conn, %{"id" => hd(inventory_lists).id, "ingredient_id" => ingredient_id})

      Enum.empty?(inventory_lists) && length(grocery_lists) == 1 ->
        RelaxirWeb.GroceryListController.add_ingredient(conn, %{"id" => hd(grocery_lists).id, "ingredient_id" => ingredient_id})

      true ->
        render(conn, "select_list.html",
          list_count: length(inventory_lists ++ grocery_lists),
          inventory_lists: inventory_lists,
          grocery_lists: grocery_lists,
          ingredient_id: ingredient_id,
          for: list_for
        )
    end
  end

  def select_list(conn, %{"ingredient_id" => ingredient_id}), do: select_list(conn, %{"ingredient_id" => ingredient_id, "for" => nil})
end
