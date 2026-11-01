defmodule GazzettaPerTutti.ActRepository.ActRecord do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:code, :string, autogenerate: false}
  schema "acts" do
    field :heading, :string
    field :issuer, :string
    field :type, :string
    field :title, :string
    field :url, :string
    field :law, :boolean, default: false
    field :published_on, :date
    field :summary, :string
    field :summarized_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end
end
