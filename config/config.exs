# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :blind_shop, :scopes,
  admin: [
    default: false,
    module: BlindShop.Admins.Scope,
    assign_key: :current_scope,
    access_path: [:admin, :id],
    schema_key: :admin_id,
    schema_type: :id,
    schema_table: :admins,
    test_data_fixture: BlindShop.AdminsFixtures,
    test_setup_helper: :register_and_log_in_admin
  ]

config :blind_shop, :scopes,
  user: [
    default: true,
    module: BlindShop.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: BlindShop.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :blind_shop,
  ecto_repos: [BlindShop.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :blind_shop, BlindShopWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BlindShopWeb.ErrorHTML, json: BlindShopWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: BlindShop.PubSub,
  live_view: [signing_salt: "1xxhXFtY"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :blind_shop, BlindShop.Mailer, adapter: Swoosh.Adapters.Local

# Configure Oban
config :blind_shop, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10, emails: 20],
  repo: BlindShop.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       # Check for shipping reminders every 6 hours
       {"0 */6 * * *", BlindShop.Workers.ShippingReminderWorker}
     ]}
  ]

# Configure Stripe
config :stripity_stripe,
  api_key: System.get_env("STRIPE_SECRET_KEY"),
  webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET")

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  blind_shop: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  blind_shop: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
