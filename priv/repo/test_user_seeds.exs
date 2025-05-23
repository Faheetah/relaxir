alias Relaxir.Accounts

accounts = [
  {"admin", true},
  {"test", true},
  {"normal", false}
]

Enum.each(accounts, fn {name, is_admin} ->
  unless Accounts.get_user_by_email("#{name}@test") do
    {:ok, _} = Accounts.register_user(%{
      email: "#{name}@test",
      username: name,
      password: name,
      password_confirmation: name,
      is_admin: is_admin
    })
  end
end)
