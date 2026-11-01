defmodule GazzettaPerTuttiWeb.HealthController do
  use GazzettaPerTuttiWeb, :controller

  def show(conn, _params), do: text(conn, "ok")
end
