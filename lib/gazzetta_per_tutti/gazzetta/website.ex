defmodule GazzettaPerTutti.Gazzetta.Website do
  @moduledoc """
  Scrapes gazzettaufficiale.it, which has no API:

    * `/30giorni/serie_generale` lists the issues of the last 30 days
    * `/eli/gu/{date}/{number}/SG/html` lists the acts of an issue
    * `/atto/vediMenuHTML` links the articles of an act, each with its text
      in `.dettaglio_atto_testo`
  """
  @behaviour GazzettaPerTutti.Gazzetta

  alias GazzettaPerTutti.Act

  @base_url "https://www.gazzettaufficiale.it"
  # More than one, so an extraordinary edition followed by a regular one isn't missed.
  @recent_issues 3
  @issue_link ~r/dataPubblicazioneGazzetta=(\d{4})-(\d{2})-(\d{2})&numeroGazzetta=(\d+)/
  @act_date ~r/dataPubblicazioneGazzetta=(\d{4})-(\d{2})-(\d{2})/
  @act_code ~r/codiceRedazionale=(\w+)/

  @impl true
  def recent_acts do
    with {:ok, list} <- get("/30giorni/serie_generale") do
      case recent_issues(list) do
        [] -> {:error, :no_issues_found}
        issues -> fetch_issues(issues)
      end
    end
  end

  @impl true
  def full_text(%Act{} = act) do
    menu_params = [
      "atto.dataPubblicazioneGazzetta": Date.to_iso8601(act.published_on),
      "atto.codiceRedazionale": act.code,
      tipoSerie: "serie_generale",
      tipoVigenza: "originario"
    ]

    with {:ok, menu} <- get("/atto/vediMenuHTML", params: menu_params),
         {:ok, articles} <- fetch_articles(article_paths(menu)) do
      {:ok, Enum.join(articles, "\n\n")}
    end
  end

  defp recent_issues(list) do
    list
    |> LazyHTML.from_document()
    |> LazyHTML.query("a.elenco_ugazzette")
    |> LazyHTML.attribute("href")
    |> Enum.flat_map(fn href ->
      case Regex.run(@issue_link, href) do
        [_, year, month, day, number] -> [{"#{year}/#{month}/#{day}", number}]
        nil -> []
      end
    end)
    |> Enum.uniq()
    |> Enum.sort_by(fn {date, number} -> {date, String.to_integer(number)} end)
    |> Enum.take(-@recent_issues)
  end

  # Sequential on purpose, to be gentle with the Gazzetta.
  defp fetch_issues(issues) do
    issues
    |> Enum.reduce_while({:ok, []}, fn {date, number}, {:ok, acts} ->
      case get("/eli/gu/#{date}/#{number}/SG/html") do
        {:ok, page} -> {:cont, {:ok, acts ++ issue_acts(page)}}
        error -> {:halt, error}
      end
    end)
  end

  # An issuer applies to the acts after it, until the next issuer or section.
  defp issue_acts(page) do
    page
    |> LazyHTML.from_document()
    |> LazyHTML.query("span.rubrica, span.emettitore, span.risultato")
    |> Enum.reduce({nil, []}, fn node, {issuer, acts} ->
      case LazyHTML.attribute(node, "class") do
        ["emettitore"] -> {squish(LazyHTML.text(node)), acts}
        ["risultato"] -> {issuer, Enum.reverse(to_act(node, issuer), acts)}
        _section -> {nil, acts}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp to_act(node, issuer) do
    href = node |> LazyHTML.query("a") |> LazyHTML.attribute("href") |> List.first("")

    with [_, year, month, day] <- Regex.run(@act_date, href),
         [_, code] <- Regex.run(@act_code, href) do
      heading = node |> LazyHTML.query("span.data") |> LazyHTML.text() |> squish()

      [
        Act.new(
          code: code,
          heading: heading,
          issuer: issuer,
          title: official_title(node, heading, code),
          url: "#{@base_url}/eli/id/#{year}/#{month}/#{day}/#{code}/SG",
          published_on: Date.from_iso8601!("#{year}-#{month}-#{day}")
        )
      ]
    else
      _ -> []
    end
  end

  # "DECRETO 20 ottobre 2026 Misure del diritto speciale ... di Livigno. (26A05686) Pag. 1"
  # -> "Misure del diritto speciale ... di Livigno."
  defp official_title(node, heading, code) do
    node
    |> LazyHTML.text()
    |> squish()
    |> String.replace_prefix(heading, "")
    |> String.split("(#{code})")
    |> hd()
    |> String.trim()
    |> case do
      "" -> heading
      title -> title
    end
  end

  defp article_paths(menu) do
    menu
    |> LazyHTML.from_document()
    |> LazyHTML.query(~s(a[href*="caricaArticolo"]))
    |> LazyHTML.attribute("href")
    |> Enum.map(&(&1 |> String.split("#") |> hd()))
    |> Enum.uniq()
  end

  defp fetch_articles(paths) do
    paths
    |> Enum.reduce_while({:ok, []}, fn path, {:ok, texts} ->
      case get(path) do
        {:ok, page} -> {:cont, {:ok, [article_text(page) | texts]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, texts} -> {:ok, texts |> Enum.reverse() |> Enum.reject(&(&1 == ""))}
      error -> error
    end
  end

  defp article_text(page) do
    page
    |> LazyHTML.from_document()
    |> LazyHTML.query(".dettaglio_atto_testo")
    |> LazyHTML.text()
    |> String.replace(" ", " ")
    |> String.split("\n")
    |> Enum.map(&squish/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp squish(text), do: text |> String.split() |> Enum.join(" ")

  defp get(path, opts \\ []) do
    [
      base_url: @base_url,
      url: path,
      headers: [user_agent: "GazzettaPerTutti/0.1"],
      receive_timeout: 30_000
    ]
    |> Keyword.merge(opts)
    |> Req.new()
    |> Req.merge(req_options())
    |> Req.get()
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) -> {:ok, body}
      {:ok, %Req.Response{status: status}} -> {:error, {:http_status, status}}
      {:error, exception} -> {:error, exception}
    end
  end

  defp req_options do
    :gazzetta_per_tutti
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:req_options, [])
  end
end
