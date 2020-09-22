alias Relaxir.Ingredients

[
  %{name: "cup"},
  %{name: "whole"},
  %{name: "tablespoon"},
  %{name: "teaspoon"},
  %{name: "pound"},
  %{name: "ounce"},
  %{name: "gram"},
]
|> Enum.each(&Ingredients.create_unit/1)
