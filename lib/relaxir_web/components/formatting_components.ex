defmodule RelaxirWeb.FormattingComponents do
  @moduledoc """
  Provides formatting UI components.
  """
  use Phoenix.Component

  alias Relaxir.Units.Unit

  attr :day, :integer, required: true
  attr :month, :integer, required: true
  attr :year, :integer, required: true

  def date(assigns) do
    months = %{1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May", 6 => "Jun", 7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec"}
    month = months[assigns.month]

    assigns = assign_new(assigns, :long_month, fn -> month end)

    ~H"""
    <span>
      <%= @long_month %> <%= @day %>, <%= @year %>
    </span>
    """
  end

  attr :name, :string, required: true
  attr :amount, :integer, required: true
  attr :unit, Unit, default: %Unit{}
  attr :note, :string

  def ingredient(assigns) do
    ~H"""
    <%= @amount %> <%= @unit && @unit.name %> <%= @name %><span class="italic text-neutral-500"><%= (@note != "" && ", #{@note}" || "")  %></span>
    """
  end
end
