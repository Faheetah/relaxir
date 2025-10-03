alias Relaxir.Accounts

unless Accounts.get_user_by_email("test@test") do
  {:ok, _} = Accounts.register_user(%{
    email: "test@test",
    username: "test",
    password: "test",
    password_confirmation: "test",
    is_admin: true
  })
end
