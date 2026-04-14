alias Relaxir.Categories

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
