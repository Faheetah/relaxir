defmodule RelaxirWeb.Features.AuthenticationPagesTest do
  use RelaxirWeb.FeatureCase, async: true
  import Query, only: [fillable_field: 1, link: 1]

  @email_field fillable_field("account[email]")
  @password_field fillable_field("account[password]")
  @password_confirmation_field fillable_field("account[password_confirmation]")

  test "Visiting the registration page", %{session: session} do
    session = visit(session, "/register")

    assert_text(session, "Register")
    assert_has(session, @email_field)
    assert_has(session, @password_field)
    assert_has(session, @password_confirmation_field)
    assert_has(session, link("Google"))
    assert_has(session, link("Twitter"))
  end

  test "Visiting the login page", %{session: session} do
    session = visit(session, "/login")

    assert_text(session, "Log In")
    assert_has(session, @email_field)
    assert_has(session, @password_field)
    assert_has(session, link("Google"))
    assert_has(session, link("Twitter"))
  end
end
