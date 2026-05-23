defmodule Relaxir.ReceiptScanner do
  @moduledoc """
  Service for scanning receipts via AI.
  """

  alias Relaxir.AI.Client
  alias Relaxir.Receipt.ScannedItem

  @receipt_prompt """
  You are a receipt parsing assistant. Analyze the receipt image and extract ALL purchased items including produce, groceries, and special items.

  Return a JSON object with the following structure:
  {
    "items": [
      {
        "name": "ingredient name as it appears on receipt (keep plural form)",
        "amount": number (quantity purchased),
        "unit": "count",
        "original_text": "the exact text from the receipt for this line"
      }
    ]
  }

  IMPORTANT RULES:
  - IGNORE PRICE COMPLETELY - DO NOT EXTRACT OR USE PRICE INFORMATION
  - IGNORE WEIGHT - TREAT EVERYTHING AS COUNT, NOT WEIGHT
  - ONLY LOOK AT COUNT (quantity)
  - If there is no count specified on the receipt, DEFAULT TO 1
  - ALWAYS use "count" as the unit (never use "lb", "oz", "kg", "liter", etc.)
  - Extract ALL purchased items including "SPECIAL" items
 r - For "SPECIAL" items, use "Unknown" as the name
  - Keep the plural form as it appears on the receipt: "POTATOES" stays "potatoes", "GRAPES" stays "grapes"
  - Fix common typos: "ZUCCHINNI" → "zucchini", "BRUSSEL" → "brussels"
  - Use lowercase for item names
  - Amount should be the quantity (count), not the price
  - Be precise with amounts (use decimals for fractions like 0.5)
  - Handle compound names: "PEAS SNOW" → "snow peas", "TOMATOES GRAPE" → "grape tomatoes"

  IMPORTANT: For "original_text", extract ONLY the ingredient name part, NOT the weight/price/metadata.

  Examples:
  - "ZUCCHINNI GREEN 0.778 kg" → {"name": "zucchini", "amount": 1, "unit": "count", "original_text": "ZUCCHINNI GREEN"}
  - "BANANA CAVENDISH 0.442kg NET @ $2.99/kg" → {"name": "banana", "amount": 1, "unit": "count", "original_text": "BANANA CAVENDISH"}
  - "POTATOES BRUSHED 1.328 kg" → {"name": "potatoes", "amount": 1, "unit": "count", "original_text": "POTATOES BRUSHED"}
  - "TOMATOES GRAPE" → {"name": "grape tomatoes", "amount": 1, "unit": "count", "original_text": "TOMATOES GRAPE"}
  - "APPLES 3" → {"name": "apples", "amount": 3, "unit": "count", "original_text": "APPLES 3"}  # Keep the count number since it's part of the item
  - "SPECIAL" → {"name": "Unknown", "amount": 1, "unit": "count", "original_text": "SPECIAL"}
  - "MILK 1 gal" → {"name": "milk", "amount": 1, "unit": "count", "original_text": "MILK"}

  Rules for original_text:
  - Extract ONLY the ingredient name words
  - Remove weight information (kg, lb, oz, g, etc.)
  - Remove price information ($, €, @, /kg, /lb, etc.)
  - Remove unit information (gal, liter, etc.) unless it's part of the name
  - Keep count numbers that are part of the item (e.g., "APPLES 3" → include "3")
  - Keep descriptive words that are part of the ingredient name (e.g., "BRUSHED", "CAVENDISH", "GREEN")
  - For items with count like "APPLES 3", extract "APPLES 3" as original_text
  - For items without explicit count, extract just the name (e.g., "BANANA CAVENDISH")
  """

  @spec scan_receipt(String.t()) :: {:ok, [ScannedItem.t()]} | {:error, term()}
  def scan_receipt(image_path) do
    scan_receipt(image_path, nil)
  end

  def scan_receipt(image_path, model_override) do
    with {:ok, image_data} <- read_and_encode_image(image_path),
         {:ok, response} <- Client.scan_image(image_data, @receipt_prompt, model_override),
         {:ok, items} <- parse_items(response) do
      {:ok, items}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_and_encode_image(image_path) do
    case File.read(image_path) do
      {:ok, data} ->
        {:ok, Base.encode64(data)}

      {:error, reason} ->
        {:error, {:file_read_error, reason}}
    end
  end

  defp parse_items(%{"items" => items}) when is_list(items) do
    scanned_items =
      items
      |> Enum.map(&ScannedItem.from_map/1)
      |> Enum.filter(&valid_item?/1)

    {:ok, scanned_items}
  end

  defp parse_items(%{"items" => items}) when not is_list(items) do
    {:error, {:invalid_format, "items is not a list"}}
  end

  defp parse_items(response) do
    {:error, {:invalid_format, response}}
  end

  defp valid_item?(%ScannedItem{name: name}) when name == "" or is_nil(name), do: false
  defp valid_item?(_), do: true
end
