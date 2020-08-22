alias Relaxir.Ingredients

[
  %{singular: "cup", plural: "cups"},
  %{singular: "whole", plural: "whole"},
  %{singular: "tablespoon", plural: "tablespoons"},
  %{singular: "teaspoon", plural: "teaspoons"},
  %{singular: "pound", plural: "pounds"},
  %{singular: "ounce", plural: "ounces"},
  %{singular: "gram", plural: "grams"},
]
|> Enum.each(&Ingredients.create_unit/1)
