defmodule GazzettaPerTutti.Repo do
  use Ecto.Repo,
    otp_app: :gazzetta_per_tutti,
    adapter: Ecto.Adapters.Postgres
end
