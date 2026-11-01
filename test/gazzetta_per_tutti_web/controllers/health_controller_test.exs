defmodule GazzettaPerTuttiWeb.HealthControllerTest do
  use GazzettaPerTuttiWeb.ConnCase, async: true

  test "reports the app is up", %{conn: conn} do
    assert conn |> get(~p"/health") |> text_response(200) == "ok"
  end
end
