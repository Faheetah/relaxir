defmodule RelaxirWeb.InventoryLive.InventoryTileComponent do
  use RelaxirWeb, :live_component

  alias RelaxirWeb.InventoryIconComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border rounded-lg shadow-sm hover:shadow-md transition-shadow relative aspect-square w-full max-w-[200px] mx-auto overflow-visible">
      <%!-- Background image --%>
      <img
        src={
          if @item.ingredient.image_filename && @item.ingredient.image_filename != "",
            do: "/uploads/#{@item.ingredient.image_filename}-full.jpg",
            else: "/images/default-full.jpg"
        }
        alt=""
        class="absolute inset-0 w-full h-full object-cover"
      />

      <%!-- Subtle gray overlay to mute the background --%>
      <div class="absolute inset-0 bg-neutral-800/50"></div>

      <%!-- Content overlay --%>
      <div class="absolute inset-0 p-2 h-full flex flex-col justify-between">
        <%!-- Top row: Inventory icon button (left) and Delete button (right) --%>
        <div class="flex justify-between items-start">
          <%!-- Inventory icon button --%>
          <div class="relative">
            <button
              type="button"
              phx-click={if @show_inventory_overlay, do: "hide_inventory_overlay", else: "show_inventory_overlay"}
              phx-target={@myself}
              class="w-10 h-8 flex items-center justify-center bg-white/20 hover:bg-white/30 text-gray-200 rounded transition-colors"
              title="Change inventory"
            >
              <%= if @item.inventory do %>
                <InventoryIconComponent.inventory_icon type={@item.inventory.icon} class="w-5 h-5 text-gray-200" />
              <% else %>
                <.icon name="hero-no-symbol" class="h-5 w-5 text-gray-200" />
              <% end %>
            </button>

            <%!-- Inventory overlay --%>
            <%= if @show_inventory_overlay do %>
              <div
                class="fixed bg-white/95 rounded-lg shadow-lg border z-[9999] min-w-[140px] max-h-48 overflow-y-auto"
                style="transform: translateY(4px);"
                phx-click-away="hide_inventory_overlay"
                phx-target={@myself}
                id="inventory-overlay-{@item.id}"
              >
                <div class="py-1">
                  <button
                    type="button"
                    phx-click="change_inventory"
                    phx-target={@myself}
                    phx-value-inventory-id=""
                    class="w-full px-3 py-2 text-left text-sm hover:bg-gray-100 flex items-center gap-2"
                  >
                    <.icon name="hero-no-symbol" class="w-4 h-4 text-gray-500" />
                    <span class="text-gray-500">No inventory</span>
                  </button>
                  <%= for inventory <- @user_inventories do %>
                    <button
                      type="button"
                      phx-click="change_inventory"
                      phx-target={@myself}
                      phx-value-inventory-id={inventory.id}
                      class={[
                        "w-full px-3 py-2 text-left text-sm hover:bg-gray-100 flex items-center gap-2",
                        if(@item.inventory_id == inventory.id, do: "bg-blue-50", else: "")
                      ]}
                    >
                      <InventoryIconComponent.inventory_icon type={inventory.icon} class="w-4 h-4" />
                      <span><%= inventory.name %></span>
                    </button>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <button
            type="button"
            phx-click="delete"
            phx-target={@myself}
            class="text-white hover:text-red-300 rounded-full"
            title="Remove from inventory"
          >
            <.icon name="hero-x-mark" class="h-6 w-6" />
          </button>
        </div>

        <%!-- Center section: Item name --%>
        <div class="flex flex-col items-center justify-center flex-1 w-full min-w-0 px-1 overflow-hidden">
          <div
            id={"item-name-#{@item.id}"}
            phx-hook="AutoResizeText"
            class="font-bold text-2xl text-white drop-shadow-lg text-center w-full line-clamp-2"
            title={@item.name || @item.ingredient.name}
          >
            <%= @item.name || @item.ingredient.name %>
          </div>
        </div>

        <%!-- Bottom section: + and - buttons with count BETWEEN them --%>
        <div class="flex justify-between items-center">
          <%!-- Decrement button (left) --%>
          <button
            type="button"
            phx-click="decrement"
            phx-target={@myself}
            class="w-10 h-8 flex items-center justify-center bg-white/20 hover:bg-white/30 text-white rounded-full disabled:opacity-30 disabled:cursor-not-allowed transition-all"
            disabled={@item.amount == 0}
            title="Decrease amount"
          >
            <.icon name="hero-minus" class="h-4 w-4" />
          </button>

          <%!-- Amount display in the middle --%>
          <div class="flex flex-col items-center justify-center flex-1 px-2">
            <div class={[
              "text-4xl font-normal drop-shadow-lg",
              if(@item.amount == 0, do: "text-red-500", else: "text-white")
            ]}>
              <%= @item.amount %>
            </div>
            <%= if @item.unit do %>
              <div class="text-sm text-white drop-shadow-lg">
                <%= @item.unit.abbreviation || @item.unit.name %>
              </div>
            <% end %>
            <%= if @item.note && @item.note != "" do %>
              <div class="text-xs text-white italic truncate drop-shadow-lg mt-1">
                "<%= @item.note %>"
              </div>
            <% end %>
          </div>

          <%!-- Increment button (right) --%>
          <button
            type="button"
            phx-click="increment"
            phx-target={@myself}
            class="w-10 h-8 flex items-center justify-center bg-white/20 hover:bg-white/30 text-white rounded-full transition-all"
            title="Increase amount"
          >
            <.icon name="hero-plus" class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("increment", _params, socket) do
    send(self(), {:increment, socket.assigns.item.id})
    {:noreply, socket}
  end

  @impl true
  def handle_event("decrement", _params, socket) do
    send(self(), {:decrement, socket.assigns.item.id})
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    send(self(), {:delete, socket.assigns.item.id})
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_inventory_overlay", _params, socket) do
    {:noreply, assign(socket, :show_inventory_overlay, true)}
  end

  @impl true
  def handle_event("hide_inventory_overlay", _params, socket) do
    {:noreply, assign(socket, :show_inventory_overlay, false)}
  end

  @impl true
  def handle_event("change_inventory", %{"inventory-id" => inventory_id}, socket) do
    item = socket.assigns.item
    inventory_id = if inventory_id == "", do: nil, else: String.to_integer(inventory_id)

    send(self(), {:change_inventory, item.id, inventory_id})
    {:noreply, assign(socket, :show_inventory_overlay, false)}
  end
end
