alias Relaxir.Repo
alias Relaxir.Users
alias Relaxir.Users.User

[
  {"admin", true},
  {"test", true},
  {"normal", false}
]
|> Enum.each(fn {name, is_admin} ->
  case Users.get_by_email("#{name}@test") do
    %User{} -> true
    _ -> %User{}
    |> User.changeset(%{email: "#{name}@test", password: name, password_confirmation: name, is_admin: is_admin})
    |> Repo.insert!()
  end
end)
