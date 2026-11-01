defmodule GazzettaPerTutti.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        GazzettaPerTuttiWeb.Telemetry,
        GazzettaPerTutti.Repo,
        {DNSCluster,
         query: Application.get_env(:gazzetta_per_tutti, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: GazzettaPerTutti.PubSub},
        GazzettaPerTuttiWeb.Endpoint
      ] ++ scheduler()

    opts = [strategy: :one_for_one, name: GazzettaPerTutti.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp scheduler do
    case Application.get_env(:gazzetta_per_tutti, :scheduler) do
      opts when is_list(opts) -> [{GazzettaPerTutti.Scheduler, opts}]
      _disabled -> []
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    GazzettaPerTuttiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
