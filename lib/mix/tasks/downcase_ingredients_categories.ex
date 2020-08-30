defmodule Mix.Tasks.Relaxir.DowncaseIngredientsCategories do
  use Mix.Task

  alias Relaxir.Repo
  alias Relaxir.Ingredients
  alias Relaxir.Categories

  @shortdoc "enforce all ingredients and categories are downcase"
  def run(_) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    Ingredients.list_ingredients()
    |> Enum.each(fn i ->
      if i.name =~ ~r(^[A-Z].*) do
        {result, _} = Ingredients.update_ingredient(i, %{name: String.downcase(i.name)})
        IO.puts "#{i.name}:#{i.id} -> #{result}"
      end

      if i.name =~ ~r(^.*\s$) do
        {result, _} = Ingredients.update_ingredient(i, %{name: String.trim(i.name)})
        IO.puts "#{i.name}:#{i.id} -> #{result}"
      end
    end)

    Categories.list_categories()
    |> Enum.each(fn i ->
      if i.name =~ ~r(^[A-Z].*) do
        {result, _} = Categories.update_category(i, %{name: String.downcase(i.name)})
        IO.puts "#{i.name}:#{i.id} -> #{result}"
      end

      if i.name =~ ~r(^.*\s$) do
        {result, _} = Categories.update_category(i, %{name: String.trim(i.name)})
        IO.puts "#{i.name}:#{i.id} -> #{result}"
      end
    end)
  end
end
