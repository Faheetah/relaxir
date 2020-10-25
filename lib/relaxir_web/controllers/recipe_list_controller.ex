defmodule RelaxirWeb.RecipeListController do
  use RelaxirWeb, :controller

  alias RelaxirWeb.Authentication
  alias Relaxir.RecipeLists
  alias Relaxir.RecipeLists.RecipeList

  def index(conn, _params) do
    current_user = Authentication.get_current_user(conn)

    recipe_lists = RecipeLists.list_recipe_lists()
    render(conn, "index.html", recipe_lists: recipe_lists, current_user: current_user)
  end

  def new(conn, _params) do
    changeset = RecipeLists.change_recipe_list(%RecipeList{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"recipe_list" => recipe_list_params}) do
    current_user = Authentication.get_current_user(conn)
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
    current_user = Authentication.get_current_user(conn)
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
end
