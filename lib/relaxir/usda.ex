defmodule Relaxir.Usda do
  import Ecto.Query, warn: false
  alias Relaxir.Repo
  alias Relaxir.Ingredients.Food

  def list_food do
    Repo.all(Food)
  end

  def get_food!(id) do
    Food
    |> Repo.get_by(fdc_id: id)
  end
end
