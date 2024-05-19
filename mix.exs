defmodule Jalka2024.MixProject do
  use Mix.Project

  def project do
    [
      app: :jalka2024,
      version: "0.1.0",
      elixir: "~> 1.14.1",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Jalka2024.Application, []},
      extra_applications: [:logger, :runtime_tools, :ssl]
    ]
  end

  defp releases() do
    [
      jalka2024: [
        include_executables_for: [:unix],
        cookie: "yQ0RMidBX8IOefY3jj1g2392x9rNJ-VwlPJOyvXnMZvQv7Ae1qsPYw=="
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0.1"},
      {:phoenix, "~> 1.6.15"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.9.0"},
      {:postgrex, ">= 0.16.5"},
      {:phoenix_live_view, "~> 0.18.3"},
      {:phoenix_live_reload, "~> 1.4"},
      {:floki, ">= 0.34.0", only: :test},
      {:dotenv_parser, "~> 2.0", only: :dev},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0.0"},
      {:gettext, "~> 0.20.0"},
      {:jason, "~> 1.4.0"},
      {:plug_cowboy, "~> 2.6"},
      {:bamboo, "~> 2.2"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:libcluster, "~> 3.3.1"},
      {:timex, "~> 3.7"}
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
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
