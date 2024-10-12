alias Relaxir.Units
alias Relaxir.Categories

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

~w[
  appetizers
  breakfast
  lunch
  mains
  sides
  condiments
  dessert
  drinks
  baking
]
|> Enum.map(fn c -> %{name: c} end)
|> Enum.each(&Categories.create_category/1)
