import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :blind_shop, BlindShop.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "blind_shop_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :blind_shop, BlindShopWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "t5kyNVDauBA6jivZfQX57fTVO2QqchGTMkHfbLQOvSNMbKYAaZTQVTuf/MCBTw8x",
  server: false

# In test we don't send emails
config :blind_shop, BlindShop.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure ExVCR for HTTP request recording/replay
config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes",
  custom_cassette_library_dir: "test/fixtures/custom_cassettes",
  filter_sensitive_data: [
    [pattern: "sk_test_[\\w]+", placeholder: "STRIPE_SECRET_KEY"],
    [pattern: "pk_test_[\\w]+", placeholder: "STRIPE_PUBLISHABLE_KEY"],
    [pattern: "whsec_[\\w]+", placeholder: "STRIPE_WEBHOOK_SECRET"]
  ]

# Configure Stripe for testing with real test keys (for VCR recording)
config :stripity_stripe,
  api_key: System.get_env("STRIPE_TEST_SECRET_KEY") || "sk_test_PLACEHOLDER",
  publishable_key: System.get_env("STRIPE_TEST_PUBLISHABLE_KEY") || "pk_test_PLACEHOLDER"
