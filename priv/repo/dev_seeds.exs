alias Relaxir.Recipes

Code.require_file("priv/repo/unit_seed.exs")

case Relaxir.Users.get_by_email("test@test") do
  %Relaxir.Users.User{} -> true
  _ -> %Relaxir.Users.User{}
  |> Relaxir.Users.User.changeset(%{email: "test@test", password: "test", password_confirmation: "test", is_admin: true})
  |> Relaxir.Repo.insert!()
end

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
