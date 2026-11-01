defmodule GazzettaPerTutti.ActRepository.Postgres do
  @moduledoc false
  @behaviour GazzettaPerTutti.ActRepository

  import Ecto.Query

  alias GazzettaPerTutti.Act
  alias GazzettaPerTutti.ActRepository.ActRecord
  alias GazzettaPerTutti.Repo

  @fields [
    :code,
    :heading,
    :issuer,
    :type,
    :title,
    :url,
    :law,
    :published_on,
    :summary,
    :summarized_at
  ]

  @impl true
  def insert_new([]), do: []

  def insert_new(acts) do
    now = DateTime.utc_now(:second)

    rows =
      acts
      |> Enum.uniq_by(& &1.code)
      |> Enum.map(&(&1 |> Map.take(@fields) |> Map.merge(%{inserted_at: now, updated_at: now})))

    # With ON CONFLICT DO NOTHING, Postgres returns only the rows actually inserted.
    {_count, records} =
      Repo.insert_all(ActRecord, rows,
        on_conflict: :nothing,
        conflict_target: :code,
        returning: true
      )

    Enum.map(records, &to_act/1)
  end

  @impl true
  def save_summary(%Act{} = act) do
    from(r in ActRecord, where: r.code == ^act.code)
    |> Repo.update_all(
      set: [
        summary: act.summary,
        summarized_at: act.summarized_at,
        updated_at: DateTime.utc_now(:second)
      ]
    )

    act
  end

  @impl true
  def list_unsummarized(limit) do
    from(r in ActRecord, where: is_nil(r.summary))
    |> most_recent_first()
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(&to_act/1)
  end

  @impl true
  def list(opts) do
    ActRecord
    |> only_laws(Keyword.get(opts, :only_laws, false))
    |> most_recent_first()
    |> limit(^Keyword.get(opts, :limit, 20))
    |> offset(^Keyword.get(opts, :offset, 0))
    |> Repo.all()
    |> Enum.map(&to_act/1)
  end

  defp only_laws(query, true), do: where(query, [r], r.law)
  defp only_laws(query, false), do: query

  defp most_recent_first(query), do: order_by(query, [r], desc: r.published_on, desc: r.code)

  defp to_act(%ActRecord{} = record), do: struct!(Act, Map.take(record, @fields))
end
