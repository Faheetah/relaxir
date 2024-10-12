alias Relaxir.Recipes

Code.require_file("priv/repo/test_user_seeds.exs")

[
  %{
    "title" => "Beef Fajitas",
    "categories" => ["Texmex"],
    "published" => true,
    "ingredients" => [
      %{name: "beef", note: "browned"},
      %{name: "onion"},
      %{name: "peppers"},
      %{name: "cheese", amount: 2, unit: "cups", note: "shredded"}
    ]
  },
  %{
    "title" => "Chicken Tacos",
    "categories" => ["texmex"],
    "ingredients" => [
      %{name: "chicken"},
      %{name: "Onion"},
      %{name: "peppers"},
      %{name: "tortillas"}
    ]
  },
  %{
    "title" => "Salsa",
    "categories" => ["Texmex", "Mexican"],
    "published" => true,
    "ingredients" => [
      %{name: "tomatoes"},
      %{name: "Onion"},
      %{name: "peppers"}
    ]
  }
]
|> Enum.each(&Recipes.create_recipe/1)
