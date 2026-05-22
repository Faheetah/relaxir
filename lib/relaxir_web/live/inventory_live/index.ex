defmodule RelaxirWeb.InventoryLive.Index do
  use RelaxirWeb, :live_view

  alias Relaxir.Inventory

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:items, [])
     |> assign(:show_add_modal, false)
     |> assign(:show_labels_modal, false)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    user_id = socket.assigns.current_user.id
    search_query = socket.assigns[:search_query] || ""

    grouped_items = Inventory.get_items_grouped_by_parent(user_id)
    user_inventories = Inventory.list_inventory_labels(user_id)

    {
      :noreply,
      socket
      |> assign(:page_title, "Inventory")
      |> assign(:grouped_items, grouped_items)
      |> assign(:user_inventories, user_inventories)
      |> assign(:search_query, search_query)
      |> assign(:search_results, [])
      |> assign(:form, to_form(%{"ingredient_search" => search_query}))
    }
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    user_id = socket.assigns.current_user.id

    search_results =
      if String.length(query) > 0 do
        Inventory.search_ingredients_not_in_items(user_id, query)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, search_results)}
  end

  @impl true
  def handle_event("validate", %{"ingredient_search" => ingredient_search}, socket) do
    user_id = socket.assigns.current_user.id

    search_results =
      if String.length(ingredient_search) > 0 do
        Inventory.search_ingredients_not_in_items(user_id, ingredient_search)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:search_query, ingredient_search)
     |> assign(:search_results, search_results)
     |> assign(:form, to_form(%{"ingredient_search" => ingredient_search}))}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    # Handle empty params case
    {:noreply, socket}
  end

  # Handle live_select selection events
  @impl true
  def handle_event("live_select_event", %{"field" => "ingredient_search", "value" => value}, socket) do
    # Update the form with the selected value
    form = to_form(%{"ingredient_search" => value})

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:search_query, value)}
  end

  @impl true
  def handle_event("add_ingredient", _params, socket) do
    user_id = socket.assigns.current_user.id

    # Get the selected value from the form params
    selected_value = socket.assigns.form.params["ingredient_search"]

    if is_nil(selected_value) or selected_value == "" do
      {:noreply, socket}
    else
      # Look up ingredient by name from search results
      search_results = socket.assigns.search_results

      found =
        Enum.find(search_results, fn ing ->
          ing.name == selected_value || "#{ing.name} (#{ing.singular})" == selected_value
        end)

      if is_nil(found) do
        {:noreply, socket}
      else
        ingredient_id = found.id

        # Check if ingredient already exists in items
        case Inventory.get_item_by_ingredient(user_id, ingredient_id) do
          nil ->
            # Create new item
            attrs = %{
              user_id: user_id,
              ingredient_id: ingredient_id,
              amount: 0
            }

            case Inventory.create_item(attrs) do
              {:ok, _item} ->
                # Refresh the grouped items
                grouped_items = Inventory.get_items_grouped_by_parent(user_id)

                {:noreply,
                 socket
                 |> assign(:grouped_items, grouped_items)
                 |> assign(:search_query, "")
                 |> assign(:search_results, [])
                 |> assign(:form, to_form(%{"ingredient_search" => ""}))}

              {:error, _changeset} ->
                {:noreply, socket}
            end

          existing_item ->
            # Update existing item amount
            case Inventory.update_item_amount(existing_item, 1) do
              {:ok, _updated_item} ->
                # Refresh the grouped items
                grouped_items = Inventory.get_items_grouped_by_parent(user_id)

                {:noreply,
                 socket
                 |> assign(:grouped_items, grouped_items)
                 |> assign(:search_query, "")
                 |> assign(:search_results, [])
                 |> assign(:form, to_form(%{"ingredient_search" => ""}))}

              {:error, _changeset} ->
                {:noreply, socket}
            end
        end
      end
    end
  end

  @impl true
  def handle_event("increment", %{"id" => id}, socket) do
    item = Inventory.get_item!(id)

    case Inventory.update_item_amount(item, 1) do
      {:ok, _updated_item} ->
        user_id = socket.assigns.current_user.id
        grouped_items = Inventory.get_items_grouped_by_parent(user_id)

        {:noreply,
         socket
         |> assign(:grouped_items, grouped_items)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to increment: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("decrement", %{"id" => id}, socket) do
    item = Inventory.get_item!(id)

    case Inventory.update_item_amount(item, -1) do
      {:ok, _updated_item} ->
        user_id = socket.assigns.current_user.id
        grouped_items = Inventory.get_items_grouped_by_parent(user_id)

        {:noreply,
         socket
         |> assign(:grouped_items, grouped_items)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to decrement: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Inventory.get_item!(id)
    {:ok, _} = Inventory.delete_item(item)

    user_id = socket.assigns.current_user.id
    grouped_items = Inventory.get_items_grouped_by_parent(user_id)

    {:noreply,
     socket
     |> put_flash(:info, "Ingredient removed from inventory")
     |> assign(:grouped_items, grouped_items)}
  end

  @impl true
  def handle_event("change_inventory", %{"id" => id, "inventory_id" => inventory_id}, socket) do
    item = Inventory.get_item!(id)
    inventory_id = if inventory_id == "", do: nil, else: String.to_integer(inventory_id)

    case Inventory.update_item(item, %{inventory_id: inventory_id}) do
      {:ok, _updated_item} ->
        user_id = socket.assigns.current_user.id
        grouped_items = Inventory.get_items_grouped_by_parent(user_id)

        {:noreply,
         socket
         |> assign(:grouped_items, grouped_items)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update inventory: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("open_labels_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_labels_modal, true)}
  end

  @impl true
  def handle_event("close_labels_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_labels_modal, false)}
  end

  @impl true
  def handle_event("create_inventory_label", %{"inventory" => inventory_params}, socket) do
    user_id = socket.assigns.current_user.id
    inventory_params = Map.put(inventory_params, "user_id", user_id)

    case Inventory.create_inventory_label(inventory_params) do
      {:ok, _inventory} ->
        user_inventories = Inventory.list_inventory_labels(user_id)

        {:noreply,
         socket
         |> assign(:user_inventories, user_inventories)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create inventory label: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("delete_inventory_label", %{"id" => id}, socket) do
    inventory = Inventory.get_inventory_label!(id)
    {:ok, _} = Inventory.delete_inventory_label(inventory)

    user_id = socket.assigns.current_user.id
    user_inventories = Inventory.list_inventory_labels(user_id)

    {:noreply,
     socket
     |> put_flash(:info, "Inventory label deleted")
     |> assign(:user_inventories, user_inventories)}
  end

  # Handle live_select changes for ingredient search
  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id, "field" => "ingredient_search"}, socket) do
    user_id = socket.assigns.current_user.id
    search_results = Inventory.search_ingredients_not_in_items(user_id, text)

    # Format results for LiveSelect dropdown
    options =
      Enum.map(search_results, fn ingredient ->
        "#{ingredient.name}" <> if ingredient.singular, do: " (#{ingredient.singular})", else: ""
      end)

    send_update(LiveSelect.Component, id: live_select_id, options: options, placeholder: "")
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_add_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_modal, true)}
  end

  @impl true
  def handle_event("close_add_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_modal, false)}
  end

  @impl true
  def handle_event("save", %{"inventory" => inventory_params}, socket) do
    user_id = socket.assigns.current_user.id
    inventory_params = Map.put(inventory_params, "user_id", user_id)

    case Inventory.create_item(inventory_params) do
      {:ok, _item} ->
        grouped_items = Inventory.get_items_grouped_by_parent(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Item created successfully")
         |> assign(:grouped_items, grouped_items)
         |> push_patch(to: ~p"/inventory")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_info({:increment, id}, socket) do
    case Inventory.get_item!(id) do
      nil ->
        {:noreply, socket}

      item ->
        case Inventory.update_item_amount(item, 1) do
          {:ok, _updated_item} ->
            user_id = socket.assigns.current_user.id
            grouped_items = Inventory.get_items_grouped_by_parent(user_id)

            {:noreply,
             socket
             |> assign(:grouped_items, grouped_items)}

          {:error, _changeset} ->
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_info({:decrement, id}, socket) do
    case Inventory.get_item!(id) do
      nil ->
        {:noreply, socket}

      item ->
        case Inventory.update_item_amount(item, -1) do
          {:ok, _updated_item} ->
            user_id = socket.assigns.current_user.id
            grouped_items = Inventory.get_items_grouped_by_parent(user_id)

            {:noreply,
             socket
             |> assign(:grouped_items, grouped_items)}

          {:error, _changeset} ->
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_info({:delete, id}, socket) do
    case Inventory.get_item!(id) do
      nil ->
        {:noreply, socket}

      item ->
        case Relaxir.Repo.delete(item) do
          {:ok, _} ->
            user_id = socket.assigns.current_user.id
            grouped_items = Inventory.get_items_grouped_by_parent(user_id)

            {:noreply,
             socket
             |> assign(:grouped_items, grouped_items)}

          {:error, _changeset} ->
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_info({:change_inventory, id, inventory_id}, socket) do
    item = Inventory.get_item!(id)

    case Inventory.update_item(item, %{inventory_id: inventory_id}) do
      {:ok, _updated_item} ->
        user_id = socket.assigns.current_user.id
        grouped_items = Inventory.get_items_grouped_by_parent(user_id)

        {:noreply,
         socket
         |> assign(:grouped_items, grouped_items)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({RelaxirWeb.InventoryLive.FormComponent, {:saved, _item}}, socket) do
    user_id = socket.assigns.current_user.id
    grouped_items = Inventory.get_items_grouped_by_parent(user_id)

    {:noreply,
     socket
     |> assign(:grouped_items, grouped_items)}
  end
end
