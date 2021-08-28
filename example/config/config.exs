# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :nested,
  ecto_repos: [Nested.Repo]

# Configures the endpoint
config :nested, NestedWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "OhEawkMknnlFF0OVrN6MCznZxybsa8/8hX2iN6oHtwucEOJmSxdBWGpPrn8hB7iw",
  render_errors: [view: NestedWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Nested.PubSub,
  live_view: [signing_salt: "YExwpGGo"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
