defmodule Relaxir.Ingredients.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeIngredient
  alias Relaxir.Usda.Food

  @derive {Jason.Encoder, only: [:id, :name]}

  schema "ingredients" do
    field :name, :string
    field :description, :string
    has_many :recipe_ingredients, RecipeIngredient
    has_many :recipes, through: [:recipe_ingredients, :recipe], on_replace: :delete
    belongs_to :food, Food

    timestamps()
  end

  def changeset(ingredient, attrs) do
    attrs =
      cond do
        Map.get(attrs, "name") -> Map.update!(attrs, "name", &String.downcase/1)
        Map.get(attrs, :name) -> Map.update!(attrs, :name, &String.downcase/1)
        true -> attrs
      end

    ingredient
    |> cast(attrs, [:name, :description])
    |> cast_assoc(:recipe_ingredients)
    |> cast_assoc(:food)
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end
