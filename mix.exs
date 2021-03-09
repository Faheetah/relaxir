defmodule Relaxir.MixProject do
  use Mix.Project

  def project do
    [
      app: :relaxir,
      version: "0.6.12",
      url: "https://github.com/Faheetah/relaxir/",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      test_coverage: [tool: LcovEx],
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Relaxir.Application, []},
      extra_applications: [:logger, :runtime_tools, :ssh]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.3"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.2.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:argon2_elixir, "~> 2.3.0"},
      {:mix_test_watch, "~> 1.0", runtime: false, only: :dev},
      {:ueberauth, "~> 0.6.3"},
      {:ueberauth_identity, "~> 0.3.0"},
      {:ueberauth_google, "~> 0.8"},
      {:guardian, "~> 2.1"},
      {:earmark, "~> 1.4.10"},
      {:csv, "~> 2.3.1"},
      {:excoveralls, "~> 0.13.1", only: :test},
      {:lcov_ex, "~> 0.1.0", runtime: false, only: :test},
      {:inflex, "~> 2.0.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.setup_dev": [
        "ecto.drop",
        "ecto.create",
        "ecto.migrate",
        "run priv/repo/dev_seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "run priv/repo/test_seeds.exs",
        "test"
      ],
      "test.clean": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/test_seeds.exs"]
    ]
  end
end
