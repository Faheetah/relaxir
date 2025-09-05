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
    <%= parse_decimal_to_fraction(@amount) %>
    <%= @unit && inflex_unit(@unit.name, @amount) %>
    <%= inflex_ingredient(@name, @unit, @amount) %><span class="italic text-neutral-500"><%= ((@note != "" && @note != nil) && ", #{@note}" || "")  %></span>
    """
  end

  defp inflex_unit(name, amount) when amount > 1, do: Inflex.pluralize(name)
  defp inflex_unit(name, _amount), do: Inflex.singularize(name)

  defp inflex_ingredient(name, nil, amount) when not is_nil(amount) and amount > 1, do: Inflex.pluralize(name)
  defp inflex_ingredient(name, _unit, _amount), do: name

  # I don't like this function but it does work and is moderately performant
  def parse_decimal_to_fraction(nil), do: nil
  def parse_decimal_to_fraction(amount) do
    # covers up to 1..100/1..100 reliably
    # can possibly cover up to 1/999999 reasonably well
    # reducing this can improve performance in case of DoS since :timer.tc 1/999999 = ~600ms
    denominator =
      1..9_999_999
      |> Enum.find(1, fn f ->
        # amount / 1 to force float, in case of amount = 1
        Float.floor(f * (amount / 1)) == f * amount
      end)

    numerator = trunc(amount * denominator)
    whole = trunc((numerator - rem(numerator, denominator)) / denominator)
    gcd = Integer.gcd(numerator, denominator)

    [whole, trunc(rem(numerator, denominator) / gcd), trunc(denominator / gcd)]
    |> case do
      [0, n, d] when n > 0 and d > 0 -> "#{n}/#{d}"
      [w, _, 1] -> w
      [w, n, d] -> "#{w} #{n}/#{d}"
    end
  end
end
