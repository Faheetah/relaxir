defmodule RelaxirWeb.IngredientController do
  use RelaxirWeb, :controller

  alias Relaxir.Ingredients
  alias Relaxir.Ingredients.Ingredient
  alias RelaxirWeb.Authentication

  def index(conn, _params) do
    current_user = Authentication.get_current_user(conn)
    ingredients = Ingredients.list_ingredients()
    render(conn, "index.html", ingredients: ingredients, current_user: current_user)
  end

  def new(conn, _params) do
    changeset = Ingredients.change_ingredient(%Ingredient{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"ingredient" => ingredient_params}) do
    case Ingredients.create_ingredient(ingredient_params) do
      {:ok, ingredient} ->
        conn
        |> put_flash(:info, "Ingredient created successfully.")
        |> redirect(to: Routes.ingredient_path(conn, :show, ingredient))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = Authentication.get_current_user(conn)
    ingredient = Ingredients.get_ingredient!(id)
    render(conn, "show.html", ingredient: ingredient, current_user: current_user)
  end

  def edit(conn, %{"id" => id}) do
    ingredient = Ingredients.get_ingredient!(id)
    changeset = Ingredients.change_ingredient(ingredient)
    render(conn, "edit.html", ingredient: ingredient, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ingredient" => ingredient_params}) do
    ingredient = Ingredients.get_ingredient!(id)

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
      length(inventory_lists) == 1 && length(grocery_lists) == 0 ->
        RelaxirWeb.InventoryListController.add_ingredient(conn, %{"id" => hd(inventory_lists).id, "ingredient_id" => ingredient_id})
      length(inventory_lists) == 0 && length(grocery_lists) == 1 ->
        RelaxirWeb.GroceryListController.add_ingredient(conn, %{"id" => hd(grocery_lists).id, "ingredient_id" => ingredient_id})
      true ->
        render(conn, "select_list.html", list_count: length(inventory_lists ++ grocery_lists), inventory_lists: inventory_lists, grocery_lists: grocery_lists, ingredient_id: ingredient_id, for: list_for)
    end
  end
  def select_list(conn, %{"ingredient_id" => ingredient_id}), do: select_list(conn, %{"ingredient_id" => ingredient_id, "for" => nil})
end
