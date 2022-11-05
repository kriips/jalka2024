defmodule Jalka2022.MixProject do
  use Mix.Project
  import Config

  def project do
    [
      app: :jalka2022,
      version: "0.1.0",
      elixir: "~> 1.14.1",
      elixirc_paths: elixirc_paths(config_env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: config_env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Jalka2022.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.9.0"},
      {:postgrex, ">= 0.16.5"},
      {:phoenix_live_view, "~> 0.18.2"},
      {:floki, ">= 0.33.1", only: :test},
      {:phoenix_html, "~> 3.1"},
      {:phoenix_live_dashboard, "~> 0.7.1"},
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0.0"},
      {:gettext, "~> 0.20.0"},
      {:jason, "~> 1.4.0"},
      {:plug_cowboy, "~> 2.5.2"},
      {:bamboo, "~> 2.2.0"}
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
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
