alias Relaxir.Recipes

case Relaxir.Users.get_by_email("test@test") do
  %Relaxir.Users.User{} -> true
  _ -> %Relaxir.Users.User{}
  |> Relaxir.Users.User.changeset(%{email: "test@test", password: "test", password_confirmation: "test", is_admin: true})
  |> Relaxir.Repo.insert!()
end

Recipes.create_recipe(%{"title" => "Beef Fajitas", "ingredients" => ["beef", "onion", "peppers", "cheese"], "categories" => ["Texmex"]}) 
Recipes.create_recipe(%{"title" => "Chicken Tacos", "ingredients" => ["chicken", "onion", "peppers", "tortillas"], "categories" => ["Texmex"]})
Recipes.create_recipe(%{"title" => "Salsa", "ingredients" => ["tomatoes", "onion", "peppers"], "categories" => ["Texmex", "Mexican"]}) 
