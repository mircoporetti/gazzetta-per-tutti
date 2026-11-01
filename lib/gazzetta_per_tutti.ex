defmodule GazzettaPerTutti do
  require Logger

  alias GazzettaPerTutti.Act

  @topic "acts"
  @explanations_per_check 30

  defp gazzetta, do: Application.fetch_env!(:gazzetta_per_tutti, :gazzetta)
  defp summarizer, do: Application.fetch_env!(:gazzetta_per_tutti, :summarizer)
  defp repository, do: Application.fetch_env!(:gazzetta_per_tutti, :act_repository)

  def check_new_acts do
    with {:ok, published} <- gazzetta().recent_acts() do
      new_acts = repository().insert_new(published)

      # Oldest first: subscribers put each act on top, so they end up newest first.
      new_acts
      |> Enum.sort_by(&{Date.to_iso8601(&1.published_on), &1.code})
      |> Enum.each(&broadcast(:act_published, &1))

      {:ok, %{new: length(new_acts), explained: explain_pending()}}
    end
  end

  def explain_pending do
    repository().list_unsummarized(@explanations_per_check)
    |> Task.async_stream(&explain/1,
      max_concurrency: 4,
      timeout: :timer.minutes(3),
      on_timeout: :kill_task
    )
    |> Enum.count(&match?({:ok, {:ok, _act}}, &1))
  end

  def list_acts(opts \\ []), do: repository().list(opts)

  @doc "Sends `{:act_published, act}` and `{:act_explained, act}` to the caller."
  def subscribe, do: Phoenix.PubSub.subscribe(GazzettaPerTutti.PubSub, @topic)

  defp explain(%Act{} = act) do
    with {:ok, full_text} <- gazzetta().full_text(act),
         {:ok, summary} <- summarizer().summarize(act, full_text) do
      act = act |> Act.summarize(summary) |> repository().save_summary()
      broadcast(:act_explained, act)
      {:ok, act}
    else
      {:error, reason} = error ->
        Logger.warning("Could not explain act #{act.code}: #{inspect(reason)}")
        error
    end
  end

  defp broadcast(event, act) do
    Phoenix.PubSub.broadcast(GazzettaPerTutti.PubSub, @topic, {event, act})
  end
end
