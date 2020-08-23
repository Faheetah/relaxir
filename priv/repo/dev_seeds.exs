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
      %{name: "beef"},
      %{name: "onion"},
      %{name: "peppers"},
      %{name: "cheese"}
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
|> Enum.each(&Recipes.create_recipe/1)
