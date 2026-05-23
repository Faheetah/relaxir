defmodule Relaxir.Receipt.ScannedItem do
  @moduledoc """
  Represents a parsed item from a receipt scan.
  """

  @type t :: %__MODULE__{
    name: String.t(),
    amount: float() | nil,
    unit: String.t() | nil,
    is_new: boolean(),
    closest_match: String.t() | nil,
    original_text: String.t() | nil
  }

  @enforce_keys [:name]
  defstruct [:name, :amount, :unit, :is_new, :closest_match, :original_text]

  @doc """
  Creates a new ScannedItem from a map.
  """
  def from_map(attrs) do
    %__MODULE__{
      name: attrs["name"] || attrs[:name] || "",
      amount: parse_amount(attrs["amount"] || attrs[:amount]),
      unit: attrs["unit"] || attrs[:unit],
      is_new: attrs["is_new"] || attrs[:is_new] || false,
      closest_match: attrs["closest_match"] || attrs[:closest_match],
      original_text: attrs["original_text"] || attrs[:original_text]
    }
  end

  defp parse_amount(nil), do: nil
  defp parse_amount(amount) when is_binary(amount) do
    case Float.parse(amount) do
      {val, _} -> val
      :error -> nil
    end
  end
  defp parse_amount(amount) when is_number(amount), do: amount
  defp parse_amount(_), do: nil
end
