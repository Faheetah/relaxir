defmodule Relaxir.AuthorizationTest do
  use ExUnit.Case, async: true
  import Relaxir.Authorization

  describe "by_user" do
    test "returns the query if user is adimn" do
      assert by_user(:foo, 1) == :foo
    end
  end
end
