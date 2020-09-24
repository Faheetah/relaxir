defmodule RelaxirWeb.RecipeParser do
  def parse_attrs(attrs) do
    attrs
    |> split_field("categories", ",")
    |> split_field("ingredients", "\n")
    |> Relaxir.Ingredients.Parser.parse_ingredients()
  end

  def split_field(attrs, name, separator) do
    field =
      (attrs[name] || "")
      |> String.split(separator)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.downcase/1)

    Map.put(attrs, name, field)
  end
end
