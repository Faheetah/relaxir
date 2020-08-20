alias Relaxir.Recipes
alias Relaxir.Ingredients

case Relaxir.Users.get_by_email("test@test") do
  %Relaxir.Users.User{} -> true
  _ -> %Relaxir.Users.User{}
  |> Relaxir.Users.User.changeset(%{email: "test@test", password: "test", password_confirmation: "test", is_admin: true})
  |> Relaxir.Repo.insert!()
end

ingredients = ["beef", "tomatoes", "lettuce", "cheese", "jalapenos", "peppers", "onion", "tortillas", "chicken"]
|> Enum.map(fn name -> Ingredients.create_ingredient(%{name: name}) end)
|> Enum.map(fn {:ok, ingredient} -> {String.to_atom(ingredient.name), %{ingredient_id: ingredient.id}} end)
|> Map.new

Recipes.create_recipe!(%{"title" => "Beef Fajitas", "recipe_ingredients" => [ingredients[:beef], ingredients[:onion], ingredients[:peppers], ingredients[:cheese]], "categories" => [%{name: "Texmex"}]}) 
Recipes.create_recipe!(%{"title" => "Chicken Tacos", "recipe_ingredients" => [ingredients[:chicken], ingredients[:onion], ingredients[:peppers], ingredients[:tortillas]], "categories" => []})
Recipes.create_recipe!(%{"title" => "Salsa", "recipe_ingredients" => [ingredients[:tomatoes], ingredients[:onion], ingredients[:peppers]], "categories" => [%{name: "Mexican"}]}) 
