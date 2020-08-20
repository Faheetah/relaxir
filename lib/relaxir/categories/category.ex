defmodule Relaxir.Categories.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeCategory
  alias Relaxir.Recipes.Recipe

  schema "categories" do
    field :name, :string
    many_to_many :recipes, Recipe, join_through: RecipeCategory, on_replace: :delete

    timestamps()
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
