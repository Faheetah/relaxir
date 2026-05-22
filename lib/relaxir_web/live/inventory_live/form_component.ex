defmodule RelaxirWeb.InventoryLive.FormComponent do
  use RelaxirWeb, :live_component

  alias Relaxir.Inventory
  alias Relaxir.Ingredients
  alias Relaxir.Units

  @impl true
  def mount(socket) do
    user_id = socket.assigns.current_user.id
    units = Units.list_units()
    ingredients = Ingredients.list_ingredients()
    user_inventories = Inventory.list_inventory_labels(user_id)

    # Prepare ingredient options for select
    ingredient_options =
      Enum.map(ingredients, fn ingredient ->
        label =
          if ingredient.parent_ingredient do
            "#{ingredient.name} (under #{ingredient.parent_ingredient.name})"
          else
            ingredient.name
          end

        {label, ingredient.id}
      end)

    # Prepare unit options for select
    unit_options = [
      {"No unit (count)", ""}
      | Enum.map(units, fn unit ->
          {"#{unit.name} (#{unit.abbreviation})", unit.id}
        end)
    ]

    # Prepare inventory label options
    inventory_options = [
      {"No label", ""}
      | Enum.map(user_inventories, fn inventory ->
          {inventory.name, inventory.id}
        end)
    ]

    {:ok,
     socket
     |> assign(:units, units)
     |> assign(:ingredients, ingredients)
     |> assign(:user_inventories, user_inventories)
     |> assign(:ingredient_options, ingredient_options)
     |> assign(:unit_options, unit_options)
     |> assign(:inventory_options, inventory_options)
     |> assign(:changeset, Inventory.change_item(%Inventory.Item{}))}
  end

  @impl true
  def update(%{action: action} = assigns, socket) do
    user_id = socket.assigns.current_user.id
    units = Units.list_units()
    ingredients = Ingredients.list_ingredients()
    user_inventories = Inventory.list_inventory_labels(user_id)

    # Prepare ingredient options for select
    ingredient_options =
      Enum.map(ingredients, fn ingredient ->
        label =
          if ingredient.parent_ingredient do
            "#{ingredient.name} (under #{ingredient.parent_ingredient.name})"
          else
            ingredient.name
          end

        {label, ingredient.id}
      end)

    # Prepare unit options for select
    unit_options = [
      {"No unit (count)", ""}
      | Enum.map(units, fn unit ->
          {"#{unit.name} (#{unit.abbreviation})", unit.id}
        end)
    ]

    # Prepare inventory label options
    inventory_options = [
      {"No label", ""}
      | Enum.map(user_inventories, fn inventory ->
          {inventory.name, inventory.id}
        end)
    ]

    # Get item from assigns or create empty one
    item = Map.get(assigns, :item, %Inventory.Item{})
    changeset = Inventory.change_item(item)

    socket =
      socket
      |> assign(assigns)
      |> assign(:units, units)
      |> assign(:ingredients, ingredients)
      |> assign(:user_inventories, user_inventories)
      |> assign(:ingredient_options, ingredient_options)
      |> assign(:unit_options, unit_options)
      |> assign(:inventory_options, inventory_options)
      |> assign(:changeset, changeset)
      |> assign(:action, action)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"item" => item_params}, socket) do
    changeset =
      %Inventory.Item{}
      |> Inventory.change_item(item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"item" => item_params}, socket) do
    save_item(socket, socket.assigns.action, item_params)
  end

  defp save_item(socket, :edit, item_params) do
    case Inventory.update_item(socket.assigns.item, item_params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Item updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_item(socket, :new, item_params) do
    # Add current user ID to params
    user_id = socket.assigns.current_user.id
    item_params = Map.put(item_params, "user_id", user_id)

    # Extract ingredient_id for duplicate check
    ingredient_id = item_params["ingredient_id"]

    # Check if ingredient already exists in items
    case Inventory.get_item_by_ingredient(user_id, ingredient_id) do
      nil ->
        # Create new item
        case Inventory.create_item(item_params) do
          {:ok, _item} ->
            {:noreply,
             socket
             |> put_flash(:info, "Item created successfully")
             |> push_patch(to: socket.assigns.patch)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      existing_item ->
        # Update existing item amount
        new_amount = (existing_item.amount || 0) + String.to_integer(item_params["amount"] || "1")

        case Inventory.update_item_amount(existing_item, new_amount - existing_item.amount) do
          {:ok, _updated_item} ->
            {:noreply,
             socket
             |> put_flash(:info, "Item amount updated (existing ingredient)")
             |> push_patch(to: socket.assigns.patch)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@changeset}
        id="item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <%!-- Ingredient selection --%>
          <.input
            type="select"
            field={@changeset[:ingredient_id]}
            label="Ingredient"
            options={@ingredient_options}
            prompt="Select an ingredient"
            required
          />

          <%!-- Name field (defaults to ingredient name) --%>
          <.input
            type="text"
            field={@changeset[:name]}
            label="Item Name"
            placeholder="Defaults to ingredient name"
          />

          <%!-- Inventory label selection --%>
          <.input
            type="select"
            field={@changeset[:inventory_id]}
            label="Inventory Label"
            options={@inventory_options}
            prompt="No label"
          />

          <%!-- Unit selection --%>
          <.input
            type="select"
            field={@changeset[:unit_id]}
            label="Unit"
            options={@unit_options}
            prompt="No unit (count)"
          />

          <%!-- Amount --%>
          <.input
            type="number"
            field={@changeset[:amount]}
            label="Amount"
            min="0"
            step="1"
          />

          <%!-- Note --%>
          <.input
            type="text"
            field={@changeset[:note]}
            label="Note"
            placeholder="Optional note about this item"
          />

          <div class="flex justify-end space-x-3 pt-4">
            <.button
              type="button"
              phx-click={JS.patch(@patch)}
              class="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Cancel
            </.button>
            <.button
              type="submit"
              class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <%= if @action == :new, do: "Add Item", else: "Update Item" %>
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
