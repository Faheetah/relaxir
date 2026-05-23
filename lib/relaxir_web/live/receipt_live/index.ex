defmodule RelaxirWeb.ReceiptLive.Index do
  use RelaxirWeb, :live_view

  import Ecto.Query

  alias Relaxir.ReceiptScanner
  alias Relaxir.Receipt.ScannedItem
  alias Relaxir.Inventory
  alias Relaxir.Inventory.Item
  alias Relaxir.Ingredients
  alias Relaxir.Repo

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:scanned_items, [])
     |> assign(:scanning, false)
     |> assign(:scan_error, nil)
     |> assign(:inventories, [])
     |> assign(:image_filename, nil)
     |> assign(:image_url, nil)
     |> assign(:scan_task_pid, nil)
     |> assign(:scan_started_at, nil)
     |> assign(:editing_item_index, nil)
     |> assign(:editing_item_search_results, [])
     |> assign(:edit_modal_open, false)
     |> assign(:editing_item, nil)}
  end

  defp start_scan_task(socket, image_filename) do
    require Logger

    # Cancel any existing scan task
    case socket.assigns.scan_task_pid do
      nil -> :ok
      pid when is_pid(pid) ->
        Logger.debug("Cancelling previous scan task: #{inspect(pid)}")
        Process.exit(pid, :kill)
    end

    # Start new scan task
    liveview_pid = self()
    {:ok, pid} = Task.start_link(fn ->
      Process.send(liveview_pid, {:scan_image, image_filename}, [])
    end)

    socket
    |> assign(:scanning, true)
    |> assign(:scanned_items, [])
    |> assign(:scan_error, nil)
    |> assign(:scan_task_pid, pid)
    |> assign(:scan_started_at, System.system_time(:millisecond))
  end

  @impl true
  def handle_params(params, _url, socket) do
    user_id = socket.assigns.current_user.id
    inventories = Inventory.list_inventory_labels(user_id)

    socket =
      socket
      |> assign(:page_title, "Receipt")
      |> assign(:inventories, inventories)

    # If we have an image_filename parameter, scan it
    case Map.get(params, "image_filename") do
      nil ->
        {:noreply, socket}

      image_filename ->
        # Find the actual image file
        image_url = get_image_url(image_filename)

        socket =
          socket
          |> assign(:image_filename, image_filename)
          |> assign(:image_url, image_url)
          |> start_scan_task(image_filename)

        {:noreply, socket}
    end
  end

  defp get_image_url(image_filename) do
    dest = Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]

    # Try to find the actual file with any extension
    try do
      case Enum.find(File.ls!(dest), &String.starts_with?(&1, "#{image_filename}-full.")) do
        nil -> "/uploads/#{image_filename}-full.jpg" # fallback
        filename -> "/uploads/#{filename}"
      end
    rescue
      _error in File.Error ->
        # Directory doesn't exist or can't be read
        "/uploads/#{image_filename}-full.jpg" # fallback
    end
  end


  @impl true
  def handle_event("add-to-inventory", %{"item-index" => index}, socket) do
    user_id = socket.assigns.current_user.id
    index = String.to_integer(index)
    scanned_items = socket.assigns.scanned_items

    case Enum.at(scanned_items, index) do
      nil ->
        {:noreply, socket}

      item ->
        amount = item.amount || 1

        # Determine ingredient_id
        ingredient_result =
          if item.is_new do
            # Create new ingredient
            case Ingredients.create_ingredient(%{name: item.name}) do
              {:ok, ingredient} -> {:ok, ingredient.id}
              {:error, changeset} -> {:error, changeset}
            end
          else
            # Look up existing ingredient by name
            case Ingredients.get_ingredient_by_name(item.name) do
              nil -> {:error, :ingredient_not_found}
              ingredient -> {:ok, ingredient.id}
            end
          end

        # Get first inventory ID
        inventory_id =
          case socket.assigns.inventories do
            [] -> nil
            [inventory | _] -> inventory.id
          end

        with {:ok, ingredient_id} <- ingredient_result,
             inventory_id when not is_nil(inventory_id) <- inventory_id do
          # Check if item already exists for this user and ingredient (unique constraint)
          existing_item =
            Item
            |> where([i], i.user_id == ^user_id and i.ingredient_id == ^ingredient_id)
            |> Repo.one()

          result =
            if existing_item do
              # Update existing item: increment amount and update inventory_id if different
              updates = %{amount: existing_item.amount + amount}
              # If inventory_id is different, update it too
              updates =
                if existing_item.inventory_id != inventory_id do
                  Map.put(updates, :inventory_id, inventory_id)
                else
                  updates
                end

              Inventory.update_item(existing_item, updates)
            else
              # Create new item
              Inventory.create_item(%{
                inventory_id: inventory_id,
                ingredient_id: ingredient_id,
                amount: amount,
                unit: "count",
                user_id: user_id
              })
            end

          case result do
            {:ok, _item} ->
              # Remove the item from scanned items
              {_removed, remaining_items} = List.pop_at(scanned_items, index)

              {:noreply,
               socket
               |> assign(:scanned_items, remaining_items)
               |> put_flash(:info, "Item added to inventory successfully")}

            {:error, changeset} ->
              {:noreply,
               socket
               |> assign(:scan_error, "Failed to add item to inventory: #{inspect(changeset.errors)}")
               |> put_flash(:error, "Failed to add item to inventory")}
          end
        else
          {:error, :ingredient_not_found} ->
            {:noreply,
             socket
             |> assign(:scan_error, "Ingredient '#{item.name}' not found")
             |> put_flash(:error, "Failed to find ingredient")}

          {:error, changeset} ->
            {:noreply,
             socket
             |> assign(:scan_error, "Failed to create ingredient: #{inspect(changeset.errors)}")
             |> put_flash(:error, "Failed to create ingredient")}

          nil ->
            {:noreply,
             socket
             |> assign(:scan_error, "No inventory found. Please create an inventory first.")
             |> put_flash(:error, "No inventory found")}

          _ ->
            {:noreply,
             socket
             |> assign(:scan_error, "Failed to add item to inventory. Please check all fields.")
             |> put_flash(:error, "Failed to add item to inventory")}
        end
    end
  end

  @impl true
  def handle_event("search-ingredients", %{"query" => query}, socket) do
    search_results = Ingredients.search_ingredients_fuzzy(query)
    {:noreply, assign(socket, :search_results, search_results)}
  end

  @impl true
  def handle_event("skip-item", %{"item-index" => index}, socket) do
    index = String.to_integer(index)
    scanned_items = socket.assigns.scanned_items

    {skipped_item, remaining_items} = List.pop_at(scanned_items, index)

    {:noreply,
     socket
     |> assign(:scanned_items, remaining_items)
     |> put_flash(:info, "Skipped #{skipped_item.name}")}
  end

  @impl true
  def handle_event("clear-all", _params, socket) do
    {:noreply,
     socket
     |> assign(:scanned_items, [])
     |> assign(:editing_item_index, nil)
     |> assign(:editing_item_search_results, [])
     |> put_flash(:info, "Cleared all scanned items")}
  end

  @impl true
  def handle_event("start-edit-item", %{"item-index" => index}, socket) do
    index = String.to_integer(index)
    scanned_items = socket.assigns.scanned_items

    case Enum.at(scanned_items, index) do
      nil ->
        {:noreply, socket}

      item ->
        # Pre-populate search with the item name or closest match
        search_query = item.closest_match || item.name
        search_results = Ingredients.search_ingredients_fuzzy(search_query) |> Enum.take(5)

        {:noreply,
         socket
         |> assign(:edit_modal_open, true)
         |> assign(:editing_item_index, index)
         |> assign(:editing_item, item)
         |> assign(:editing_item_search_results, search_results)}
    end
  end

  @impl true
  def handle_event("close-edit-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:edit_modal_open, false)
     |> assign(:editing_item_index, nil)
     |> assign(:editing_item, nil)
     |> assign(:editing_item_search_results, [])}
  end

  @impl true
  def handle_event("live_select_event", %{"field" => "item_name_edit", "value" => value}, socket) do
    # Update search results as user types - limit to top 5 matches
    search_results = Ingredients.search_ingredients_fuzzy(value) |> Enum.take(5)

    {:noreply,
     socket
     |> assign(:editing_item_search_results, search_results)}
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => _live_select_id, "field" => "item_name_edit"}, socket) do
    # Update search results as user types - limit to top 5 matches
    search_results = Ingredients.search_ingredients_fuzzy(text) |> Enum.take(5)

    {:noreply,
     socket
     |> assign(:editing_item_search_results, search_results)}
  end

  @impl true
  def handle_event("select-ingredient", %{"ingredient-id" => ingredient_id}, socket) do
    ingredient_id = String.to_integer(ingredient_id)
    index = socket.assigns.editing_item_index
    scanned_items = socket.assigns.scanned_items

    case {Enum.at(scanned_items, index), Ingredients.get_ingredient!(ingredient_id)} do
      {nil, _} ->
        {:noreply, socket}

      {item, ingredient} ->
        # Update the item with the selected ingredient
        updated_item = %{item | name: ingredient.name, is_new: false, closest_match: nil}
        updated_items = List.replace_at(scanned_items, index, updated_item)

        {:noreply,
         socket
         |> assign(:scanned_items, updated_items)
         |> assign(:edit_modal_open, false)
         |> assign(:editing_item_index, nil)
         |> assign(:editing_item, nil)
         |> assign(:editing_item_search_results, [])
         |> put_flash(:info, "Updated #{item.name} to #{ingredient.name}")}
    end
  end


  @impl true
  def handle_info({:scan_image, image_filename}, socket) do
    require Logger
    Logger.debug("Starting receipt scan for image: #{image_filename}")

    # Construct the full path to the uploaded image
    dest = Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]

    # Try to find the actual file with any extension
    # First check if file exists with .jpg extension (for backward compatibility)
    image_path_with_jpg = Path.join([dest, "#{image_filename}-full.jpg"])

    image_path =
      if File.exists?(image_path_with_jpg) do
        image_path_with_jpg
      else
        # Try to find any file matching pattern
        try do
          case Enum.find(File.ls!(dest), &String.starts_with?(&1, "#{image_filename}-full.")) do
            nil -> image_path_with_jpg # fallback
            filename -> Path.join(dest, filename)
          end
        rescue
          _error in File.Error ->
            image_path_with_jpg # fallback
        end
      end

    Logger.debug("Image path: #{image_path}")

    try do
      case ReceiptScanner.scan_receipt(image_path) do
        {:ok, scanned_items} ->
          Logger.debug("Successfully scanned #{length(scanned_items)} items")
          # Mark items as new if they don't exist in ingredients and find closest matches
          marked_items =
            scanned_items
            |> Enum.map(fn %ScannedItem{} = item ->
              existing_ingredient = Ingredients.get_ingredient_by_name(item.name)

              if is_nil(existing_ingredient) do
                # Item is new, find closest match
                closest_matches = Ingredients.search_ingredients_fuzzy(item.name)
                closest_match = List.first(closest_matches)

                %{item |
                  is_new: true,
                  closest_match: if(closest_match, do: closest_match.name, else: nil)
                }
              else
                %{item | is_new: false, closest_match: nil}
              end
            end)

          {:noreply,
           socket
           |> assign(:scanned_items, marked_items)
           |> assign(:scanning, false)
           |> assign(:scan_error, nil)
           |> assign(:scan_task_pid, nil)
           |> assign(:scan_started_at, nil)}

        {:error, reason} ->
          Logger.error("Failed to scan receipt: #{inspect(reason)}")

          # Format a user-friendly error message
          error_message =
            case reason do
              :configuration_missing ->
                "AI API configuration missing. Please set AI_API_ENDPOINT, AI_API_KEY, and AI_MODEL environment variables."
              {:api_error, 401, _} ->
                "AI API authentication failed. Please check your AI_API_KEY environment variable."
              {:api_error, 404, _} ->
                "AI API endpoint not found (404). Please check your AI_API_ENDPOINT configuration."
              {:api_error, status, body} when is_binary(body) and byte_size(body) > 0 ->
                "AI API error #{status}: #{body}"
              {:api_error, status, _} ->
                "AI API error #{status}. Please check your AI API configuration."
              {:request_error, error_reason} ->
                "Network error: #{inspect(error_reason)}"
              {:parse_error, _} ->
                "Failed to parse AI response. The API may have returned invalid JSON."
              {:file_read_error, :enoent} ->
                "Receipt image file not found. Please try uploading the receipt again."
              _ ->
                "Failed to scan receipt: #{inspect(reason)}"
            end

          {:noreply,
           socket
           |> assign(:scanned_items, [])
           |> assign(:scanning, false)
           |> assign(:scan_error, error_message)
           |> assign(:scan_task_pid, nil)
           |> assign(:scan_started_at, nil)}
      end
    rescue
      error in [RuntimeError] ->
        if error.message == "AI_API_BASE_URL not configured" do
          Logger.error("AI API not configured - cannot scan receipt")
          {:noreply,
           socket
           |> assign(:scanned_items, [])
           |> assign(:scanning, false)
           |> assign(:scan_error, "AI API is not configured. Please configure AI_API_BASE_URL environment variable to enable receipt scanning.")
           |> assign(:scan_task_pid, nil)
           |> assign(:scan_started_at, nil)}
        else
          reraise error, __STACKTRACE__
        end
    end
  end
end
