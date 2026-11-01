import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :gazzetta_per_tutti, GazzettaPerTutti.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "gazzetta_per_tutti_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gazzetta_per_tutti, GazzettaPerTuttiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "x/BI5EdnoFFwTg2Rsny1NA3/TQMueO4m7cIetDfC5mcywXTtwIgqtIuUt/T5UD8e",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :gazzetta_per_tutti,
  gazzetta: GazzettaPerTutti.GazzettaMock,
  summarizer: GazzettaPerTutti.SummarizerMock,
  scheduler: false

config :gazzetta_per_tutti, GazzettaPerTutti.Gazzetta.Website,
  req_options: [plug: {Req.Test, GazzettaPerTutti.Gazzetta.Website}, retry: false]

config :gazzetta_per_tutti, GazzettaPerTutti.Summarizer.Claude,
  api_key: "test-api-key",
  req_options: [plug: {Req.Test, GazzettaPerTutti.Summarizer.Claude}, retry: false]

config :gazzetta_per_tutti, GazzettaPerTutti.Summarizer.OpenAI,
  api_key: "test-api-key",
  req_options: [plug: {Req.Test, GazzettaPerTutti.Summarizer.OpenAI}, retry: false]
