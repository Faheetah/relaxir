defmodule RelaxirWeb.GroceryListController do
  use RelaxirWeb, :controller

  alias Relaxir.GroceryLists
  alias Relaxir.GroceryLists.GroceryList

  def index(conn, _params) do
    current_user = conn.assigns.current_user

    grocery_lists = GroceryLists.list_grocery_lists()
    render(conn, "index.html", grocery_lists: grocery_lists, current_user: current_user)
  end

  def new(conn, _params) do
    changeset = GroceryLists.change_grocery_list(%GroceryList{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"grocery_list" => grocery_list_params}) do
    current_user = conn.assigns.current_user
    grocery_list_params = Map.put(grocery_list_params, "user_id", current_user.id)

    case GroceryLists.create_grocery_list(grocery_list_params) do
      {:ok, grocery_list} ->
        conn
        |> put_flash(:info, "Grocery list created successfully.")
        |> redirect(to: Routes.grocery_list_path(conn, :show, grocery_list))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    grocery_list = GroceryLists.get_grocery_list!(id)
    render(conn, "show.html", grocery_list: grocery_list, current_user: current_user)
  end

  def edit(conn, %{"id" => id}) do
    grocery_list = GroceryLists.get_grocery_list!(id)
    changeset = GroceryLists.change_grocery_list(grocery_list)
    render(conn, "edit.html", grocery_list: grocery_list, changeset: changeset)
  end

  def update(conn, %{"id" => id, "grocery_list" => grocery_list_params}) do
    grocery_list = GroceryLists.get_grocery_list!(id)

    case GroceryLists.update_grocery_list(grocery_list, grocery_list_params) do
      {:ok, grocery_list} ->
        redirect(conn, to: Routes.grocery_list_path(conn, :show, grocery_list))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", grocery_list: grocery_list, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    grocery_list = GroceryLists.get_grocery_list!(id)
    {:ok, _grocery_list} = GroceryLists.delete_grocery_list(grocery_list)

    conn
    |> put_flash(:info, "Grocery list deleted successfully.")
    |> redirect(to: Routes.grocery_list_path(conn, :index))
  end

  def remove_ingredient(conn, %{"id" => id, "ingredient_id" => ingredient_id}) do
    grocery_list = GroceryLists.get_grocery_list!(id)

    GroceryLists.remove_ingredient(grocery_list, String.to_integer(ingredient_id))
    redirect(conn, to: Routes.grocery_list_path(conn, :show, grocery_list))
  end

  def add_ingredient(conn, %{"id" => id, "ingredient_id" => ingredient_id}) do
    grocery_list = GroceryLists.get_grocery_list!(id)

    ingredient_id = cond do
      is_integer(ingredient_id) -> ingredient_id
      is_binary(ingredient_id) -> String.to_integer(ingredient_id)
    end

    case GroceryLists.add_ingredient(grocery_list, ingredient_id) do
      :ok ->
        conn
        |> redirect(to: Routes.grocery_list_path(conn, :show, grocery_list))
      _ ->
        conn
        |> redirect(to: Routes.grocery_list_path(conn, :show, grocery_list))
    end
  end
end
