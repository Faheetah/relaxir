defmodule Relaxir.UnitsTest do
  use Relaxir.DataCase

  alias Relaxir.Units

  @singular "couch"
  @plural "couches"

  describe "units" do
    test "creates a unit" do
      {:ok, unit} = Units.create_unit(%{name: @singular})
      assert unit.name == @singular
    end

    test "creates a unit as singular" do
      {:ok, unit} = Units.create_unit(%{name: @plural})
      assert unit.name == @singular
    end

    test "gets a unit by singular name" do
      Units.create_unit(%{name: @singular})
      unit = Units.get_unit_by_name(@singular)
      assert unit.name == @singular
    end

    test "gets a unit by plural name" do
      Units.create_unit(%{name: @plural})
      unit = Units.get_unit_by_name(@plural)
      assert unit.name == @singular
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
