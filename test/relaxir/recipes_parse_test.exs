defmodule Relaxir.RecipesParseTest do
  use Relaxir.DataCase, async: true

  alias Relaxir.Recipes

  describe "parse_ingredient_with_units/2" do
    test "handles unparsable unit strings gracefully" do
      # This should return an error when Unit.parse returns {:error, "1"}
      assert {:error, _reason} = Recipes.parse_ingredient_with_units("1 something, note")
    end

    test "handles strings with no recognizable units" do
      # This should also return an error
      assert {:error, _reason} = Recipes.parse_ingredient_with_units("2 whatever")
    end
  end
end
