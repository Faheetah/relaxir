defmodule Relaxir.Categories.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeCategory

  schema "categories" do
    field :name, :string
    field :image_filename, :string
    has_many :recipe_categories, RecipeCategory, on_delete: :delete_all
    has_many :recipes, through: [:recipe_categories, :recipe], on_replace: :delete

    timestamps()
  end

  def changeset(category, attrs) do
    attrs =
      cond do
        Map.get(attrs, "name") -> Map.update!(attrs, "name", &String.downcase/1)
        Map.get(attrs, :name) -> Map.update!(attrs, :name, &String.downcase/1)
        true -> attrs
      end

    category
    |> cast(attrs, [:name, :image_filename])
    |> cast_assoc(:recipe_categories)
    |> validate_required([:name])
    |> validate_format(:name, ~r/[^a-z]/)
    |> unique_constraint([:name])
  end
end
