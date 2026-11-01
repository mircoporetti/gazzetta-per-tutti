defmodule GazzettaPerTuttiWeb.ActsLiveTest do
  use GazzettaPerTuttiWeb.ConnCase

  import Mox
  import Phoenix.LiveViewTest
  import GazzettaPerTutti.ActsFixtures

  alias GazzettaPerTutti.GazzettaMock
  alias GazzettaPerTutti.SummarizerMock

  setup :verify_on_exit!

  defp published_in_gazzetta(acts, summary \\ "Spiegazione semplice") do
    stub(GazzettaMock, :recent_acts, fn -> {:ok, acts} end)
    stub(GazzettaMock, :full_text, fn _act -> {:ok, "Testo"} end)
    stub(SummarizerMock, :summarize, fn _act, _text -> {:ok, summary} end)
    {:ok, _} = GazzettaPerTutti.check_new_acts()
  end

  test "a reader sees the latest acts explained, with a link to the official text", %{conn: conn} do
    published_in_gazzetta(
      [law()],
      "Cambiano le regole per la plastica riciclata usata per il cibo."
    )

    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#act-26G00217 h2", "Materiali di plastica riciclata")
    assert has_element?(view, "#act-26G00217 .act-summary", "Cambiano le regole per la plastica")

    assert has_element?(
             view,
             ~s(#act-26G00217 a.act-source[href="https://www.gazzettaufficiale.it/eli/id/2026/10/30/26G00217/SG"])
           )
  end

  test "the most recent acts come first", %{conn: conn} do
    published_in_gazzetta([
      law(code: "26G00210", published_on: ~D[2026-10-28]),
      ministerial_decree(published_on: ~D[2026-10-31])
    ])

    {:ok, view, _html} = live(conn, ~p"/?atti=tutti")

    assert view |> element("#acts li:first-child") |> render() =~ ~s(id="act-26A05686")
    assert has_element?(view, "#act-26A05686 time", "31 ottobre 2026")
  end

  test "a reader sees only laws by default, and can switch to all acts", %{conn: conn} do
    published_in_gazzetta([law(), ministerial_decree()])

    {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, "#filter-laws[aria-current=page]")
    assert has_element?(view, "#act-26G00217")
    refute has_element?(view, "#act-26A05686")

    view |> element("#filter-all") |> render_click()
    assert_patch(view, ~p"/?atti=tutti")
    assert has_element?(view, "#act-26A05686")

    view |> element("#filter-laws") |> render_click()
    assert_patch(view, ~p"/")
    refute has_element?(view, "#act-26A05686")
  end

  test "a reader can go back to older acts", %{conn: conn} do
    published_in_gazzetta(
      for n <- 1..25 do
        ministerial_decree(code: "26A0#{5600 + n}", published_on: Date.add(~D[2026-10-31], -n))
      end
    )

    {:ok, view, _html} = live(conn, ~p"/?atti=tutti")
    assert has_element?(view, "#act-26A05601")
    refute has_element?(view, "#act-26A05625")

    view |> element("#load-more") |> render_click()

    assert has_element?(view, "#act-26A05625")
    refute has_element?(view, "#load-more")
  end

  test "new acts appear while the page is open, and their explanation follows", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, "#acts-empty")

    stub(GazzettaMock, :recent_acts, fn -> {:ok, [law()]} end)
    stub(GazzettaMock, :full_text, fn _act -> {:ok, "Testo"} end)
    stub(SummarizerMock, :summarize, fn _act, _text -> {:error, :overloaded} end)
    {:ok, _} = GazzettaPerTutti.check_new_acts()

    assert has_element?(view, "#act-26G00217 .act-summary-pending")
    refute has_element?(view, "#acts-empty")

    stub(SummarizerMock, :summarize, fn _act, _text -> {:ok, "Ora è spiegato"} end)
    {:ok, _} = GazzettaPerTutti.check_new_acts()

    assert has_element?(view, "#act-26G00217 .act-summary", "Ora è spiegato")
  end

  test "readers are told that explanations are automatic", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "Fa fede solo il testo pubblicato nella Gazzetta Ufficiale"
  end
end
