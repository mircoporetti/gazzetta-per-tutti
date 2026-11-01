defmodule GazzettaPerTutti.Scheduler do
  use GenServer

  require Logger

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    Process.send_after(self(), :check, Keyword.get(opts, :first_check_in, :timer.seconds(10)))
    {:ok, %{every: Keyword.fetch!(opts, :every)}}
  end

  @impl true
  def handle_info(:check, state) do
    check()
    Process.send_after(self(), :check, state.every)
    {:noreply, state}
  end

  defp check do
    case GazzettaPerTutti.check_new_acts() do
      {:ok, %{new: new, explained: explained}} ->
        Logger.info("Gazzetta checked: #{new} new acts, #{explained} explained")

      {:error, reason} ->
        Logger.warning("Gazzetta check failed: #{inspect(reason)}")
    end
  rescue
    exception ->
      Logger.error(
        "Gazzetta check crashed: " <> Exception.format(:error, exception, __STACKTRACE__)
      )
  end
end
