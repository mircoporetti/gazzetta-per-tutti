defmodule GazzettaPerTutti.Act do
  @enforce_keys [:code, :heading, :title, :url, :published_on]
  defstruct [
    :code,
    :heading,
    :issuer,
    :type,
    :title,
    :url,
    :published_on,
    :summary,
    :summarized_at,
    law: false
  ]

  @type t :: %__MODULE__{
          code: String.t(),
          heading: String.t(),
          issuer: String.t() | nil,
          type: String.t(),
          title: String.t(),
          url: String.t(),
          published_on: Date.t(),
          summary: String.t() | nil,
          summarized_at: DateTime.t() | nil,
          law: boolean()
        }

  # In the "codice redazionale", G marks primary legislation and A everything else.
  @law_code ~r/^\d{2}G\d+$/
  # "DECRETO LEGISLATIVO 9 ottobre 2026, n. 199" -> "DECRETO LEGISLATIVO"
  @type_in_heading ~r/^(.+?)\s+\d{1,2}°?\s+\p{L}+\s+\d{4}/u

  def new(attrs) do
    act = struct!(__MODULE__, attrs)
    %{act | type: type_from(act), law: Regex.match?(@law_code, act.code)}
  end

  def summarize(%__MODULE__{} = act, summary, at \\ DateTime.utc_now(:second)) do
    %{act | summary: summary, summarized_at: at}
  end

  defp type_from(%__MODULE__{heading: heading, issuer: issuer}) do
    type =
      case Regex.run(@type_in_heading, heading) do
        [_, type] -> String.capitalize(type)
        nil -> String.capitalize(heading)
      end

    if type == "Decreto" and ministry?(issuer), do: "Decreto ministeriale", else: type
  end

  defp ministry?(issuer), do: is_binary(issuer) and String.starts_with?(issuer, "MINISTERO")
end
