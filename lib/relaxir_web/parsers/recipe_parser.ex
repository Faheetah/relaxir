defmodule RelaxirWeb.RecipeParser do
  def parse_attrs(attrs) do
    attrs
    |> split_field("categories", ",")
    |> split_field("ingredients", "\n")
    |> parse_ingredients()
  end

  def split_field(attrs, name, separator) do
    field =
      (attrs[name] || "")
      |> String.split(separator)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    Map.put(attrs, name, field)
  end

  def parse_ingredients(attrs) do
    ingredients =
      attrs["ingredients"]
      |> Enum.map(&%{name: &1})

    Map.put(attrs, "ingredients", ingredients)
  end
end
