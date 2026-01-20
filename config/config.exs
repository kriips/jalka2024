# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :jalka2026,
  ecto_repos: [Jalka2026.Repo]

# Configures the endpoint
config :jalka2026, Jalka2026Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "3U8JC5dFuT0k2cZDTb/WVERkDV5E4xqZ4rzfW44vvbeSHVUiMshTHHnhu7BEdJiy",
  render_errors: [view: Jalka2026Web.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Jalka2026.PubSub,
  live_view: [signing_salt: "HRQbNn1t/mSJlj9R9CIx9CjOq3PMzZ14"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :jalka2026, env: config_env()

config :jalka2026, compile_env: Mix.env()

config :esbuild,
  version: "0.14.0",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    #      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
