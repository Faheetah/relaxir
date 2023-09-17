defmodule Relaxir.MixProject do
  use Mix.Project

  def project do
    [
      app: :relaxir,
      version: "0.8.3",
      url: "https://github.com/Faheetah/relaxir/",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
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
      # Phoenix related
      {:plug_cowboy, "~> 2.6"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.19"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:jason, "~>1.4"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      # initial auth generation, now baked into Phoenix
      # {:phx_gen_auth, "~> 0.7.0"},
      # DB related
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},
      # telemetry
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0"},
      # misc required for app
      {:bcrypt_elixir, "~> 3.1"},
      {:gettext, "~> 0.11"},
      {:earmark, "~> 1.4"},
      {:csv, "~> 3.0.5"},
      {:inflex, "~> 2.1.0"},
      {:invert, git: "https://github.com/faheetah/invert", tag: "0.3.0"},
      # test and code quality
      {:mix_test_watch, "~> 1.1", runtime: false, only: :dev},
      {:credo, "~> 1.7", only: :dev},
      {:excoveralls, "~> 0.17", only: :test},
      {:sobelow, "~> 0.13", only: :dev}
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
      "test.clean": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/test_seeds.exs"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
