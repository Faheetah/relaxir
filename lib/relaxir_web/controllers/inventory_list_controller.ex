defmodule RelaxirWeb.InventoryListController do
  use RelaxirWeb, :controller

  alias RelaxirWeb.Authentication
  alias Relaxir.InventoryLists
  alias Relaxir.InventoryLists.InventoryList

  def index(conn, _params) do
    current_user = Authentication.get_current_user(conn)

    inventory_lists = InventoryLists.list_inventory_lists()
    render(conn, "index.html", inventory_lists: inventory_lists, current_user: current_user)
  end

  def new(conn, _params) do
    changeset = InventoryLists.change_inventory_list(%InventoryList{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"inventory_list" => inventory_list_params}) do
    current_user = Authentication.get_current_user(conn)
    inventory_list_params = Map.put(inventory_list_params, "user_id", current_user.id)

    case InventoryLists.create_inventory_list(inventory_list_params) do
      {:ok, inventory_list} ->
        conn
        |> put_flash(:info, "Inventory list created successfully.")
        |> redirect(to: Routes.inventory_list_path(conn, :show, inventory_list))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    inventory_list = InventoryLists.get_inventory_list!(id)
    render(conn, "show.html", inventory_list: inventory_list)
  end

  def edit(conn, %{"id" => id}) do
    inventory_list = InventoryLists.get_inventory_list!(id)
    changeset = InventoryLists.change_inventory_list(inventory_list)
    render(conn, "edit.html", inventory_list: inventory_list, changeset: changeset)
  end

  def update(conn, %{"id" => id, "inventory_list" => inventory_list_params}) do
    inventory_list = InventoryLists.get_inventory_list!(id)

    case InventoryLists.update_inventory_list(inventory_list, inventory_list_params) do
      {:ok, inventory_list} ->
        conn
        |> put_flash(:info, "Inventory list updated successfully.")
        |> redirect(to: Routes.inventory_list_path(conn, :show, inventory_list))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", inventory_list: inventory_list, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    inventory_list = InventoryLists.get_inventory_list!(id)
    {:ok, _inventory_list} = InventoryLists.delete_inventory_list(inventory_list)

    conn
    |> put_flash(:info, "Inventory list deleted successfully.")
    |> redirect(to: Routes.inventory_list_path(conn, :index))
  end

  def remove_ingredient(conn, %{"id" => id, "ingredient_id" => ingredient_id}) do
    inventory_list = InventoryLists.get_inventory_list!(id)

    InventoryLists.remove_ingredient(inventory_list, String.to_integer(ingredient_id))
    redirect(conn, to: Routes.inventory_list_path(conn, :show, inventory_list))
  end

  def add_ingredient(conn, %{"id" => id, "ingredient_id" => ingredient_id}) do
    inventory_list = InventoryLists.get_inventory_list!(id)

    ingredient_id = cond do
      is_integer(ingredient_id) -> ingredient_id
      is_binary(ingredient_id) -> String.to_integer(ingredient_id)
    end

    case InventoryLists.add_ingredient(inventory_list, ingredient_id) do
      :ok ->
        conn
        |> redirect(to: Routes.inventory_list_path(conn, :show, inventory_list))
      _ ->
        conn
        |> redirect(to: Routes.inventory_list_path(conn, :show, inventory_list))
    end
  end
end
