defmodule RelaxirWeb.RecipeLive.FormComponent do
  use RelaxirWeb, :live_component

  alias Relaxir.Recipes
  alias Relaxir.Categories

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage recipe records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="recipe-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <.input field={@form[:title]} type="text" label="Title" />

        <.input field={@form[:description]} type="textarea" label="Description" />

        <.live_select
          field={@form[:categories]}
          phx-target={@myself}
          mode={:tags}
          dropdown_extra_class="mt-4"
          option_extra_class="py-2"
          style={:tailwind}
        />

        <.input field={@form[:directions]} type="textarea" label="Directions" />

        <.input field={@form[:note]} type="textarea" label="Note" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Recipe</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{recipe: recipe} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Recipes.change_recipe(recipe))
     end)}
  end

  @impl true
  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    changeset = Recipes.change_recipe(socket.assigns.recipe, recipe_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    save_recipe(socket, socket.assigns.action, recipe_params)
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id, "field" => field}, socket) do
    IO.inspect field
    items =
      case field do
        "recipe_categories" -> Categories.search_categories(text)
      end

    send_update(LiveSelect.Component, id: live_select_id, options: [text | items])

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear", %{"id" => id}, socket) do
    send_update(LiveSelect.Component, options: [], id: id)

    {:noreply, socket}
  end

  defp save_recipe(socket, :edit, recipe_params) do
    case Recipes.update_recipe(socket.assigns.recipe, recipe_params) do
      {:ok, recipe} ->
        notify_parent({:saved, recipe})

        {:noreply,
         socket
         |> put_flash(:info, "Recipe updated successfully")
         |> push_navigate(to: ~p"/recipes/#{recipe.id}")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, assign(socket, form: to_form(Recipes.change_recipe(socket.assigns.recipe, recipe_params)))}
    end
  end

  defp save_recipe(socket, :new, recipe_params) do
    case Recipes.create_recipe(recipe_params) do
      {:ok, recipe} ->
        notify_parent({:saved, recipe})

        {:noreply,
         socket
         |> put_flash(:info, "Recipe created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
