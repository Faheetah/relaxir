alias Relaxir.Recipes

Code.require_file("priv/repo/unit_seeds.exs")
Code.require_file("priv/repo/test_user_seeds.exs")

[
  %{
    "title" => "Beef Fajitas",
    "categories" => ["Texmex"],
    "ingredients" => [
      %{name: "beef", note: "browned"},
      %{name: "onion"},
      %{name: "peppers"},
      %{name: "cheese", amount: 2, unit: "cups", note: "shredded"}
    ]
  },
  %{
    "title" => "Chicken Tacos",
    "categories" => ["Texmex"],
    "ingredients" => [
      %{name: "chicken"},
      %{name: "onion"},
      %{name: "peppers"},
      %{name: "tortillas"}
    ]
  },
  %{
    "title" => "Salsa",
    "categories" => ["Texmex", "Mexican"],
    "ingredients" => [
      %{name: "tomatoes"},
      %{name: "onion"},
      %{name: "peppers"}
    ]
  }
]
|> Enum.map(&Recipes.create_recipe/1)
