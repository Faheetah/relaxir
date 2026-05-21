defmodule Relaxir.RecipesParseTest do
  use Relaxir.DataCase, async: true

  alias Relaxir.Recipes

  describe "parse_ingredient_with_units/2" do
    test "handles unparsable unit strings gracefully" do
      # With the new parse_count_based_ingredient fallback, this should return {:ok, ...}
      assert {:ok, [amount, unit, ingredient, note]} = Recipes.parse_ingredient_with_units("1 something, note")
      assert amount == "1.0"
      assert unit == ""
      assert ingredient == "something"
      assert note == "note"
    end

    test "handles strings with no recognizable units" do
      # With the new parse_count_based_ingredient fallback, this should return {:ok, ...}
      assert {:ok, [amount, unit, ingredient, note]} = Recipes.parse_ingredient_with_units("2 whatever")
      assert amount == "2.0"
      assert unit == ""
      assert ingredient == "whatever"
      assert note == ""
    end
  end
end
