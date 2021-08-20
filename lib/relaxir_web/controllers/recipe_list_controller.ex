defmodule RelaxirWeb.RecipeListController do
  use RelaxirWeb, :controller

  alias Relaxir.RecipeLists
  alias Relaxir.RecipeLists.RecipeList

  def index(conn, _params) do
    current_user = conn.assigns.current_user

    recipe_lists = RecipeLists.list_recipe_lists()
    render(conn, "index.html", recipe_lists: recipe_lists, current_user: current_user)
  end

  def new(conn, _params) do
    changeset = RecipeLists.change_recipe_list(%RecipeList{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"recipe_list" => recipe_list_params}) do
    current_user = conn.assigns.current_user
    recipe_list_params = Map.put(recipe_list_params, "user_id", current_user.id)

    case RecipeLists.create_recipe_list(recipe_list_params) do
      {:ok, recipe_list} ->
        conn
        |> put_flash(:info, "Recipe list created successfully.")
        |> redirect(to: Routes.recipe_list_path(conn, :show, recipe_list))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user
    recipe_list = RecipeLists.get_recipe_list!(id)
    render(conn, "show.html", recipe_list: recipe_list, current_user: current_user)
  end

  def edit(conn, %{"id" => id}) do
    recipe_list = RecipeLists.get_recipe_list!(id)
    changeset = RecipeLists.change_recipe_list(recipe_list)
    render(conn, "edit.html", recipe_list: recipe_list, changeset: changeset)
  end

  def update(conn, %{"id" => id, "recipe_list" => recipe_list_params}) do
    recipe_list = RecipeLists.get_recipe_list!(id)

    case RecipeLists.update_recipe_list(recipe_list, recipe_list_params) do
      {:ok, recipe_list} ->
        conn
        |> put_flash(:info, "Recipe list updated successfully.")
        |> redirect(to: Routes.recipe_list_path(conn, :show, recipe_list))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", recipe_list: recipe_list, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    recipe_list = RecipeLists.get_recipe_list!(id)
    {:ok, _recipe_list} = RecipeLists.delete_recipe_list(recipe_list)

    conn
    |> put_flash(:info, "Recipe list deleted successfully.")
    |> redirect(to: Routes.recipe_list_path(conn, :index))
  end

  def remove_recipe(conn, %{"id" => id, "recipe_id" => recipe_id}) do
    recipe_list = RecipeLists.get_recipe_list!(id)

    RecipeLists.remove_recipe(recipe_list, String.to_integer(recipe_id))

    conn
    |> put_flash(:info, "Recipe removed successfully.")
    |> redirect(to: Routes.recipe_list_path(conn, :show, recipe_list))
  end

  def select_list(conn, %{"recipe_id" => recipe_id}) do
    recipe_lists = RecipeLists.list_recipe_lists()

    case recipe_lists do
      [recipe_list] ->
        add_recipe(conn, %{"id" => recipe_list.id, "recipe_id" => recipe_id})

      _ ->
        render(conn, "select_list.html", recipe_lists: recipe_lists, recipe_id: recipe_id)
    end
  end

  def add_recipe(conn, %{"id" => id, "recipe_id" => recipe_id}) do
    recipe_list = RecipeLists.get_recipe_list!(id)

    case RecipeLists.add_recipe(recipe_list, String.to_integer(recipe_id)) do
      :ok ->
        conn
        |> put_flash(:info, "Recipe added successfully.")
        |> redirect(to: Routes.recipe_list_path(conn, :show, recipe_list))

      _ ->
        conn
        |> redirect(to: Routes.recipe_list_path(conn, :show, recipe_list))
    end
  end
end
