defmodule Relaxir.UnitsTest do
  use Relaxir.DataCase

  alias Relaxir.Units

  @singular "tinyspoon"
  @plural "tinyspoons"
  @abbreviation "tsp"
  @abbreviation_plural "tsps"

  describe "units" do
    test "creates a unit" do
      {:ok, unit} = Units.create_unit(%{name: @singular, abbreviation: @abbreviation})
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "creates a unit as singular" do
      {:ok, unit} = Units.create_unit(%{name: @plural, abbreviation: @abbreviation_plural})
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "gets a unit by singular name" do
      Units.create_unit(%{name: @singular, abbreviation: @abbreviation})
      unit = Units.get_unit_by_name(@singular)
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "gets a unit by plural name" do
      Units.create_unit(%{name: @plural, abbreviation: @abbreviation_plural})
      unit = Units.get_unit_by_name(@plural)
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "gets a unit by plural abbreviation" do
      Units.create_unit(%{name: @plural, abbreviation: @abbreviation_plural})
      unit = Units.get_unit_by_name(@abbreviation_plural)
      assert unit.name == @singular
      assert unit.abbreviation == @abbreviation
    end

    test "returns nil for missing unit" do
      unit = Units.get_unit_by_name(@singular)
      assert unit == nil
    end

    test "lists all units" do
      Units.create_unit(%{name: @singular})
      units = Units.list_units()
      assert length(units) > 0
    end
  end
end
