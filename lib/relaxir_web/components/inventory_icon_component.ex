defmodule RelaxirWeb.InventoryIconComponent do
  use Phoenix.Component

  @moduledoc """
  SVG icons for inventory types.
  """

  @doc """
  Renders an inventory icon based on the icon type.
  """
  attr :type, :string, required: true
  attr :class, :string, default: "w-6 h-6"

  def inventory_icon(assigns) do
    ~H"""
    <%= case @type do %>
      <% "refrigerator_top" -> %>
        <svg viewBox="0 0 24 24" class={@class} fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="2" width="14" height="20" rx="1" />
          <line x1="5" y1="8" x2="19" y2="8" />
          <line x1="16" y1="4" x2="16" y2="6" />
          <line x1="16" y1="10" x2="16" y2="12" />
        </svg>

      <% "refrigerator_french" -> %>
        <svg viewBox="0 0 24 24" class={@class} fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="2" width="14" height="20" rx="1" />
          <line x1="12" y1="2" x2="12" y2="22" />
          <line x1="8" y1="10" x2="8" y2="12" />
          <line x1="16" y1="10" x2="16" y2="12" />
        </svg>

      <% "freezer_chest" -> %>
        <svg viewBox="0 0 24 24" class={@class} fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="6" width="14" height="14" rx="1" />
          <line x1="5" y1="10" x2="19" y2="10" />
          <line x1="9" y1="7" x2="15" y2="7" />
        </svg>

      <% "shelf" -> %>
        <svg viewBox="0 0 24 24" class={@class} fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="4" width="14" height="16" rx="1" />
          <line x1="5" y1="9" x2="19" y2="9" />
          <line x1="5" y1="15" x2="19" y2="15" />
        </svg>

      <% "table" -> %>
        <svg viewBox="0 0 24 24" class={@class} fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <rect x="4" y="6" width="16" height="3" rx="0.5" />
          <line x1="7" y1="9" x2="7" y2="20" />
          <line x1="17" y1="9" x2="17" y2="20" />
          <line x1="4" y1="20" x2="20" y2="20" />
        </svg>

      <% _ -> %>
        <svg viewBox="0 0 24 24" class={@class} fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="4" width="14" height="16" rx="1" />
          <line x1="5" y1="10" x2="19" y2="10" />
          <line x1="5" y1="16" x2="19" y2="16" />
        </svg>
    <% end %>
    """
  end
end
