defmodule GazzettaPerTuttiTest do
  use GazzettaPerTutti.DataCase, async: true

  import Mox
  import GazzettaPerTutti.ActsFixtures

  alias GazzettaPerTutti.GazzettaMock
  alias GazzettaPerTutti.SummarizerMock

  setup :verify_on_exit!

  defp published_in_gazzetta(acts), do: stub(GazzettaMock, :recent_acts, fn -> {:ok, acts} end)

  defp full_text_available,
    do: stub(GazzettaMock, :full_text, fn act -> {:ok, "Testo di #{act.code}"} end)

  defp explained_as(fun), do: stub(SummarizerMock, :summarize, fun)

  describe "check_new_acts/0" do
    test "new acts in the Gazzetta are stored with their plain explanation" do
      published_in_gazzetta([law()])
      full_text_available()

      explained_as(fn act, "Testo di 26G00217" ->
        assert act.code == "26G00217"
        {:ok, "Cambiano le regole per la plastica riciclata usata per il cibo."}
      end)

      assert {:ok, %{new: 1, explained: 1}} = GazzettaPerTutti.check_new_acts()

      assert [act] = GazzettaPerTutti.list_acts()
      assert act.summary == "Cambiano le regole per la plastica riciclata usata per il cibo."
      assert act.url == "https://www.gazzettaufficiale.it/eli/id/2026/10/30/26G00217/SG"
      assert act.type == "Decreto legislativo"
      assert act.law
    end

    test "an act already explained is never explained again" do
      published_in_gazzetta([law()])
      full_text_available()
      expect(SummarizerMock, :summarize, 1, fn _act, _text -> {:ok, "Spiegazione"} end)

      {:ok, _} = GazzettaPerTutti.check_new_acts()

      assert {:ok, %{new: 0, explained: 0}} = GazzettaPerTutti.check_new_acts()
      assert [_only_one] = GazzettaPerTutti.list_acts()
    end

    test "an act that could not be explained is retried at the next check" do
      published_in_gazzetta([law()])
      full_text_available()

      expect(SummarizerMock, :summarize, fn _act, _text -> {:error, :overloaded} end)
      assert {:ok, %{new: 1, explained: 0}} = GazzettaPerTutti.check_new_acts()
      assert [%{summary: nil}] = GazzettaPerTutti.list_acts()

      expect(SummarizerMock, :summarize, fn _act, _text -> {:ok, "Spiegazione"} end)
      assert {:ok, %{new: 0, explained: 1}} = GazzettaPerTutti.check_new_acts()
      assert [%{summary: "Spiegazione"}] = GazzettaPerTutti.list_acts()
    end

    test "when the full text can't be read the act is not explained, and stays listed" do
      published_in_gazzetta([law()])
      stub(GazzettaMock, :full_text, fn _act -> {:error, {:http_status, 503}} end)

      assert {:ok, %{new: 1, explained: 0}} = GazzettaPerTutti.check_new_acts()
      assert [%{code: "26G00217", summary: nil}] = GazzettaPerTutti.list_acts()
    end

    test "when the Gazzetta is unreachable nothing changes" do
      stub(GazzettaMock, :recent_acts, fn -> {:error, :timeout} end)

      assert {:error, :timeout} = GazzettaPerTutti.check_new_acts()
      assert GazzettaPerTutti.list_acts() == []
    end

    test "subscribers hear about new acts and then about their explanation" do
      GazzettaPerTutti.subscribe()
      published_in_gazzetta([law()])
      full_text_available()
      explained_as(fn _act, _text -> {:ok, "Spiegazione"} end)

      {:ok, _} = GazzettaPerTutti.check_new_acts()

      assert_receive {:act_published, %{code: "26G00217", summary: nil}}
      assert_receive {:act_explained, %{code: "26G00217", summary: "Spiegazione"}}
    end
  end

  describe "list_acts/1" do
    setup do
      published_in_gazzetta([
        law(code: "26G00210", published_on: ~D[2026-10-28]),
        ministerial_decree(code: "26A05686", published_on: ~D[2026-10-31]),
        law(code: "26G00217", published_on: ~D[2026-10-30])
      ])

      full_text_available()
      explained_as(fn _act, _text -> {:ok, "Spiegazione"} end)
      {:ok, _} = GazzettaPerTutti.check_new_acts()
      :ok
    end

    test "shows the most recent acts first" do
      assert ["26A05686", "26G00217", "26G00210"] = codes(GazzettaPerTutti.list_acts())
    end

    test "can show only laws, leaving out ministerial decrees and notices" do
      assert ["26G00217", "26G00210"] = codes(GazzettaPerTutti.list_acts(only_laws: true))
    end

    test "is paginated" do
      assert ["26G00217"] = codes(GazzettaPerTutti.list_acts(limit: 1, offset: 1))
    end
  end

  defp codes(acts), do: Enum.map(acts, & &1.code)
end
