alias Relaxir.Units

[
  %{name: "cup", abbreviation: "c"},
  %{name: "whole"},
  %{name: "tablespoon", abbreviation: "tbsp"},
  %{name: "teaspoon", abbreviation: "tsp"},
  %{name: "pound", abbreviation: "lb"},
  %{name: "ounce", abbreviation: "oz"},
  %{name: "gram", abbreviation: "g"}
]
|> Enum.each(&Units.create_unit/1)
