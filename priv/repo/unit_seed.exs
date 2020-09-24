alias Relaxir.Units

[
  %{name: "cup"},
  %{name: "whole"},
  %{name: "tablespoon"},
  %{name: "teaspoon"},
  %{name: "pound"},
  %{name: "ounce"},
  %{name: "gram"},
]
|> Enum.each(&Units.create_unit/1)
