# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :servidor_central, ServidorCentral.Repo,
  database: "azar_1_repo",
  username: "postgres",
  password: "mateus",
  hostname: "localhost",
  port: 5432

config :servidor_central, ecto_repos: [ServidorCentral.Repo]
config :cliente_admin, ecto_repos: []
config :cliente_jugador, ecto_repos: []
# Sample configuration:
#
#     config :logger, :default_handler,
#       level: :info
#
#     config :logger, :default_formatter,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#
