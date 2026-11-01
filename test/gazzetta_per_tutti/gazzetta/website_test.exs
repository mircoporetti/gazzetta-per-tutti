defmodule GazzettaPerTutti.Gazzetta.WebsiteTest do
  # Fixtures recorded from the real website on 2026-11-01 (latest issue: n. 254).
  use ExUnit.Case, async: true

  import GazzettaPerTutti.ActsFixtures, only: [fixture: 1, ministerial_decree: 0]

  alias GazzettaPerTutti.Gazzetta.Website

  defp gazzetta_online do
    test_pid = self()

    Req.Test.stub(Website, fn conn ->
      send(test_pid, {:requested, conn.request_path})

      case conn.request_path do
        "/30giorni/serie_generale" -> Req.Test.html(conn, fixture("issues_list.html"))
        "/eli/gu/2026/10/29/252/SG/html" -> Req.Test.html(conn, fixture("issue_252.html"))
        "/eli/gu/2026/10/30/253/SG/html" -> Req.Test.html(conn, fixture("issue_253.html"))
        "/eli/gu/2026/10/31/254/SG/html" -> Req.Test.html(conn, fixture("issue_254.html"))
      end
    end)
  end

  defp find(acts, code), do: Enum.find(acts, &(&1.code == code))

  describe "recent_acts/0" do
    test "lists every act of the three most recent issues" do
      gazzetta_online()

      assert {:ok, acts} = Website.recent_acts()

      assert length(acts) == 15 + 27 + 19
      assert_received {:requested, "/eli/gu/2026/10/29/252/SG/html"}
      assert_received {:requested, "/eli/gu/2026/10/30/253/SG/html"}
      assert_received {:requested, "/eli/gu/2026/10/31/254/SG/html"}
      refute_received {:requested, "/eli/gu/2026/10/28/251/SG/html"}
    end

    test "reads laws, which have no issuer" do
      gazzetta_online()

      {:ok, acts} = Website.recent_acts()

      assert %{
               issuer: nil,
               heading: "DECRETO LEGISLATIVO 9 ottobre 2026, n. 199",
               type: "Decreto legislativo",
               law: true,
               url: "https://www.gazzettaufficiale.it/eli/id/2026/10/30/26G00217/SG",
               published_on: ~D[2026-10-30]
             } = law = find(acts, "26G00217")

      assert law.title =~ ~r/^Disposizioni di attuazione dell'articolo 27 della legge/
      assert law.title =~ ~r/a contatto con i prodotti alimentari\.$/
    end

    test "reads ministerial decrees with their issuer" do
      gazzetta_online()

      {:ok, acts} = Website.recent_acts()

      assert %{
               issuer: "MINISTERO DELL'ECONOMIA E DELLE FINANZE",
               heading: "DECRETO 20 ottobre 2026",
               type: "Decreto ministeriale",
               title:
                 "Misure del diritto speciale sulla benzina, petrolio, gasolio ed altri generi, istituito nel territorio extradoganale di Livigno.",
               url: "https://www.gazzettaufficiale.it/eli/id/2026/10/31/26A05686/SG",
               law: false
             } = find(acts, "26A05686")
    end

    test "keeps the whole issuer when it has several levels" do
      gazzetta_online()

      {:ok, acts} = Website.recent_acts()

      assert %{
               issuer:
                 "PRESIDENZA DEL CONSIGLIO DEI MINISTRI - COMMISSARIO STRAORDINARIO DI GOVERNO PER LA REALIZZAZIONE DEL NUOVO POLICLINICO UMBERTO I",
               type: "Ordinanza"
             } = find(acts, "26A05699")
    end

    test "an issuer applies only to the acts of its own section" do
      gazzetta_online()

      {:ok, acts} = Website.recent_acts()

      assert %{issuer: nil, heading: "DECRETO DEL PRESIDENTE DELLA REPUBBLICA 15 ottobre 2026"} =
               find(acts, "26A05675")

      assert %{issuer: "MINISTERO DELL'AGRICOLTURA, DELLA SOVRANITA' ALIMENTARE E DELLE FORESTE"} =
               find(acts, "26A05634")
    end

    test "reports when the Gazzetta does not answer properly" do
      Req.Test.stub(Website, &Plug.Conn.send_resp(&1, 503, "down"))

      assert {:error, {:http_status, 503}} = Website.recent_acts()
    end

    test "reports when the list of issues can't be understood" do
      Req.Test.stub(Website, &Req.Test.html(&1, "<html><body>Manutenzione</body></html>"))

      assert {:error, :no_issues_found} = Website.recent_acts()
    end
  end

  describe "full_text/1" do
    test "joins the text of every article and annex of the act" do
      Req.Test.stub(Website, fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)

        page =
          case {conn.request_path, conn.query_params} do
            {"/atto/vediMenuHTML", %{"atto.codiceRedazionale" => "26A05686"}} ->
              "act_menu_26A05686.html"

            {"/atto/serie_generale/caricaArticolo", %{"art.flagTipoArticolo" => "1"}} ->
              "act_annex_26A05686_1.html"

            {"/atto/serie_generale/caricaArticolo", %{"art.idArticolo" => n}} ->
              "act_article_26A05686_#{n}.html"
          end

        Req.Test.html(conn, fixture(page))
      end)

      assert {:ok, text} = Website.full_text(ministerial_decree())

      assert text =~ "IL VICE MINISTRO DELL'ECONOMIA"
      assert text =~ "Art. 2\n1. L'aliquota da applicare"
      assert text =~ "periodo 1° gennaio-31 dicembre 2027."
      assert text =~ "Allegato A"
      refute text =~ "<"
    end

    test "fails when an article can't be read" do
      Req.Test.stub(Website, fn
        %{request_path: "/atto/vediMenuHTML"} = conn ->
          Req.Test.html(conn, fixture("act_menu_26A05686.html"))

        conn ->
          Plug.Conn.send_resp(conn, 500, "error")
      end)

      assert {:error, {:http_status, 500}} = Website.full_text(ministerial_decree())
    end
  end
end
