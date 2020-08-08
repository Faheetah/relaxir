defmodule Relaxir.Ingredients.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeIngredient
  alias Relaxir.Recipes.Recipe

  @derive {Jason.Encoder, only: [:id, :name]}

  schema "ingredients" do
    field :name, :string
    many_to_many :recipes, Recipe, join_through: RecipeIngredient

    timestamps()
  end

  @doc false
  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
