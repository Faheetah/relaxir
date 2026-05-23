defmodule RelaxirWeb.ReceiptLive.IndexTest do
  use RelaxirWeb.ConnCase, async: true

  describe "Receipt" do
    test "requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/receipt")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "upload route requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/receipts/upload?path=&redirect=/receipt")
      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end

  describe "Receipt for authenticated user" do
    setup :register_and_log_in_user

    test "renders receipt page", %{conn: conn} do
      conn = get(conn, ~p"/receipt")
      assert html_response(conn, 200) =~ "Receipt"
    end

    test "upload route works with required parameters", %{conn: conn} do
      conn = get(conn, ~p"/receipts/upload?path=&redirect=/receipt")
      assert html_response(conn, 200) =~ "Upload"
    end
  end
end
