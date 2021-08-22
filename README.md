[![Elixir CI](https://github.com/Faheetah/relaxir/actions/workflows/ci.yml/badge.svg)](https://github.com/Faheetah/relaxir/actions/workflows/ci.yml)

# Setup

Install Elixir

```
mix local.hex --force
mix local.rebar --force
mix deps.get
npm install --prefix ./assets
npm run deploy --prefix ./assets
mix phx.digest
```

# Dev

```
mix ecto.reset
mix relaxir.add_user email=test@test password=test admin=true
mix relaxir.seed_db
iex -S mix phx.server
```

Or inside of phx.server

```
Mix.Tasks.Relaxir.AddUser.run(["email=test@test", "password=test", "admin=true"])
Mix.Tasks.Relaxir.SeedDb.run([])
```

# Tests

Run unit tests, code quality tests, and static security scan

```
mix test --cover
mix credo
mix sobelow --skip -i Config.HTTPS
```

For local development, ensure all files are formatted, i.e.

```
mix format "{lib,test,config}/**/*.{ex,exs}"
```

Alternatively, a `tests.sh` script is included that will run all of the above and only display output of failures. This can be handy as a git hook.

# Prod

Increment version in mix.esx

Add a tag for the version, found with `mix relaxir.version`

Push with tags

Wait for the build job

```
mix relaxir.deploy
```

Or deploy from local workspace

```
mix relaxir.local_deploy relaxanddine.com
```

# USDA Data

Can be found at https://fdc.nal.usda.gov/portal-data/external/dataDictionary

Load it in with:

```
mix relaxir.import Food ../../food-data/food.csv
```
