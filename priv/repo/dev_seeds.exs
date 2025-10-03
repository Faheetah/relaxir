alias Relaxir.Recipes

Code.require_file("priv/repo/test_user_seeds.exs")

[
  %{
    "title" => "Beef Fajitas",
    "categories" => ["Texmex"],
    "published" => true,
    "recipe_ingredients" => [
      "||beef|browned",
      "||onion|",
      "||peppers|",
      "2|cups|cheese|shredded"
    ]
  },
  %{
    "title" => "Chicken Tacos",
    "categories" => ["texmex"],
    "recipe_ingredients" => [
      "||chicken|",
      "||Onion|",
      "||peppers|",
      "||tortillas|"
    ]
  },
  %{
    "title" => "Salsa",
    "categories" => ["Texmex", "Mexican"],
    "published" => true,
    "recipe_ingredients" => [
      "||tomatoes|",
      "||Onion|",
      "||peppers|"
    ]
  }
]
|> Enum.each(&Recipes.create_recipe/1)
