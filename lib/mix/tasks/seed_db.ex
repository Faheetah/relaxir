defmodule Mix.Tasks.Relaxir.SeedDb do
  use Mix.Task

  alias Relaxir.Repo
  alias Relaxir.Ingredients
  alias Relaxir.Recipes

  @shortdoc "Seed a database with example data"
  def run(_) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)
    Repo.start_link

    ["Tomatoes", "Lettuce", "Cheese", "Jalapenos"]
    |> Enum.each(& Ingredients.create_ingredient(%{name: &1}))

    Recipes.create_recipe(%{"title" => "Beef Fajitas", "ingredients" => "Beef\nOnion\nBell Pepper"})
    Recipes.create_recipe(%{"title" => "Chicken Tacos", "ingredients" => "Chicken\nOnion\nJalapenos\nTortillas"})
    Recipes.create_recipe(%{"title" => "Salsa", "ingredients" => "Tomatoes\nOnion\nJalapenos"})
  end
end

