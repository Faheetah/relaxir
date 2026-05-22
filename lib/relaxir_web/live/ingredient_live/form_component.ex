defmodule RelaxirWeb.IngredientLive.FormComponent do
  use RelaxirWeb, :live_component

  alias Relaxir.Ingredients
  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.Recipes

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

        <.input field={@form[:singular]} type="text" label="Singular" />

        <.input field={@form[:description]} type="textarea" label="Description" />

        <div>
          <.label>Parent Ingredient</.label>
          <.live_select
            field={@form[:parent_ingredient_id]}
            phx-target={@myself}
            mode={:single}
            allow_clear={true}
            dropdown_extra_class="mt-4"
            option_extra_class="py-2"
            container_extra_class="flex flex-col mt-2"
            text_input_extra_class="border-neutral-300 focus:ring-0 focus:border-neutral-400"
            placeholder="Select parent ingredient (optional)"
            style={:tailwind}
          />
        </div>

        <div>
          <.label>Source Recipe</.label>
          <.live_select
            field={@form[:source_recipe_id]}
            phx-target={@myself}
            mode={:single}
            allow_clear={true}
            dropdown_extra_class="mt-4"
            option_extra_class="py-2"
            container_extra_class="flex flex-col mt-2"
            text_input_extra_class="border-neutral-300 focus:ring-0 focus:border-neutral-400"
            placeholder="Select source recipe (optional)"
            style={:tailwind}
          />
        </div>

        <.input field={@form[:image_filename]} type="text" label="Image Filename" />

        <%= if @ingredient.id do %>
        <.link
          class="flex bg-neutral-900 text-white text-4xl"
          navigate={~p"/images/#{@ingredient}/upload?#{%{redirect: "/ingredients/#{@ingredient.id}/upload", path: @ingredient.image_filename || ""}}"}
        >
          <span class="place-self-center text-center w-full">Upload an image</span>
        </.link>
        <% end %>

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
      Relaxir.Units.list_units()
      |> Enum.flat_map(fn u -> [u.name, u.abbreviation] end)
      |> Enum.reject(&(&1 == nil))

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

  # Handle live_select changes for parent_ingredient_id
  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id, "field" => "ingredient_parent_ingredient_id"}, socket) do
    items = Ingredients.search_ingredients(text)
    send_update(LiveSelect.Component, id: live_select_id, options: [text | items], placeholder: "")
    {:noreply, socket}
  end

  # Handle live_select changes for source_recipe_id
  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id, "field" => "ingredient_source_recipe_id"}, socket) do
    items = Recipes.search_recipes(text)
    send_update(LiveSelect.Component, id: live_select_id, options: [text | items], placeholder: "")
    {:noreply, socket}
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

  defp save_ingredient(socket, :new, ingredient_params) do
    case Ingredients.create_ingredient(ingredient_params) do
      {:ok, ingredient} ->
        notify_parent({:saved, ingredient})

        {:noreply,
         socket
         |> put_flash(:info, "Ingredient created successfully")
         |> push_navigate(to: ~p"/ingredients/#{ingredient.id}/#{ingredient.name}")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, assign(socket, form: to_form(Ingredients.change_ingredient(%Ingredient{}, ingredient_params)))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
