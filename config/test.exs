import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :picture_whisper, PictureWhisper.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "picture_whisper_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :picture_whisper, PictureWhisperWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qKuFix4PUdI0Dj1OiP5rT/MV89i8oezx/F5EcZnRJW6VCxV4h5aM6yb13xK27f/A",
  server: false

# In test we don't send emails
config :picture_whisper, PictureWhisper.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure number of free images allowed per user
# Keep at 10 for testing purposes
config :picture_whisper, :max_global_key_images, 10
