defmodule Relaxir.UnitParsingTest do
  use ExUnit.Case, async: true

  alias Relaxir.Recipes

  describe "parse_ingredient_with_units/1" do
    test "parses 1 cup, noted as invalid (no ingredient)" do
      assert {:ok, ["1.0", "cup", "", "noted"]} = Recipes.parse_ingredient_with_units("1 cup, noted")
    end

    test "parses 1 cup flour, sifted correctly" do
      assert {:ok, ["1.0", "cup", "flour", "sifted"]} = Recipes.parse_ingredient_with_units("1 cup flour, sifted")
    end

    test "parses 2 cups sugar" do
      assert {:ok, ["2.0", "cup", "sugar", ""]} = Recipes.parse_ingredient_with_units("2 cups sugar")
    end

    test "parses 3 eggs" do
      assert {:ok, ["3.0", "", "eggs", ""]} = Recipes.parse_ingredient_with_units("3 eggs")
    end
  end
end
