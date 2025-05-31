defmodule RelaxirWeb.IngredientLive.FormComponent do
  use RelaxirWeb, :live_component

  alias Relaxir.Ingredients

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @name %>
        <:subtitle>Use this form to manage ingredient records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="ingredient-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <.input field={@form[:name]} type="text" label="Name" />

        <.input field={@form[:image_filename]} type="text" label="Image Filename" />

        <.link
          class="flex bg-neutral-900 text-white text-4xl"
          navigate={~p"/images/#{@ingredient}/upload?#{%{redirect: "/ingredients/#{@ingredient.id}/upload", path: @ingredient.image_filename || ""}}"}
        >
          <span class="place-self-center text-center w-full">Upload an image</span>
        </.link>

        <:actions>
          <.button phx-disable-with="Saving...">Save Ingredient</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{ingredient: ingredient} = assigns, socket) do
    units =
      Relaxir.Units.list_units
      |> Enum.flat_map(fn u -> [u.name, u.abbreviation] end)
      |> Enum.reject(& &1 == nil)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:units, units)
     |> assign_new(:form, fn ->
       to_form(Ingredients.change_ingredient(ingredient))
     end)}
  end

  @impl true
  def handle_event("validate", %{"ingredient" => ingredient_params}, socket) do
    changeset = Ingredients.change_ingredient(socket.assigns.ingredient, ingredient_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"ingredient" => ingredient_params}, socket) do
    save_ingredient(socket, socket.assigns.action, ingredient_params)
  end

  defp save_ingredient(socket, :edit, ingredient_params) do
    case Ingredients.update_ingredient(socket.assigns.ingredient, ingredient_params) do
      {:ok, ingredient} ->
        notify_parent({:saved, ingredient})

        {:noreply,
         socket
         |> put_flash(:info, "Ingredient updated successfully")
         |> push_navigate(to: ~p"/ingredients/#{ingredient.id}/#{ingredient.name}")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, assign(socket, form: to_form(Ingredients.change_ingredient(socket.assigns.ingredient, ingredient_params)))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
