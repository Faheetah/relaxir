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
    months = %{
      1 => "Jan",
      2 => "Feb",
      3 => "Mar",
      4 => "Apr",
      5 => "May",
      6 => "Jun",
      7 => "Jul",
      8 => "Aug",
      9 => "Sep",
      10 => "Oct",
      11 => "Nov",
      12 => "Dec"
    }

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
  attr :singular, :string, default: nil

  def ingredient(assigns) do
    ~H"""
    <%= parse_decimal_to_fraction(@amount) %>
    <%= @unit && inflex_unit(@unit.name, @amount) %>
    <%= inflex_ingredient(@name, @singular, @unit, @amount) %><span class="italic text-neutral-500"><%= ((@note != "" && @note != nil) && ", #{@note}" || "")  %></span>
    """
  end

  defp inflex_unit(name, amount) when is_binary(amount) do
    case Float.parse(amount) do
      {float_amount, ""} -> inflex_unit(name, float_amount)
      {float_amount, _rest} -> inflex_unit(name, float_amount)
      :error -> Inflex.singularize(name)
    end
  end

  defp inflex_unit(name, amount) when amount > 1, do: Inflex.pluralize(name)
  defp inflex_unit(name, _amount), do: Inflex.singularize(name)

  # Use stored singular field if available, otherwise inflect from name
  defp inflex_ingredient(name, singular, unit, amount) when is_binary(amount) do
    case Float.parse(amount) do
      {float_amount, ""} -> inflex_ingredient(name, singular, unit, float_amount)
      {float_amount, _rest} -> inflex_ingredient(name, singular, unit, float_amount)
      :error -> inflex_ingredient(name, singular, unit, 1)
    end
  end

  defp inflex_ingredient(name, singular, _unit, amount) when not is_nil(amount) and amount > 1 do
    # Use stored plural form if available (singular + "s" is a reasonable default)
    plural = if singular, do: singular <> "s", else: Inflex.pluralize(name)
    plural
  end

  defp inflex_ingredient(name, singular, _unit, _amount) do
    # Use stored singular form if available, otherwise inflect from name
    if singular, do: singular, else: name
  end

  # I don't like this function but it does work and is moderately performant
  def parse_decimal_to_fraction(nil), do: nil

  def parse_decimal_to_fraction(amount) when is_binary(amount) do
    case Float.parse(amount) do
      {float_amount, ""} -> parse_decimal_to_fraction(float_amount)
      {_float_amount, _rest} -> amount
      :error -> amount
    end
  end

  def parse_decimal_to_fraction(amount) when is_integer(amount) do
    parse_decimal_to_fraction(amount / 1)
  end

  def parse_decimal_to_fraction(amount) when is_float(amount) do
    # Denominator range for fraction parsing
    # Higher values support more precise fractions but take longer to compute
    max_denominator = 100_000

    denominator =
      1..max_denominator
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
