defmodule GazzettaPerTutti.ActsFixtures do
  @moduledoc false

  alias GazzettaPerTutti.Act

  def law(attrs \\ []) do
    [
      code: "26G00217",
      heading: "DECRETO LEGISLATIVO 9 ottobre 2026, n. 199",
      issuer: nil,
      title: "Materiali di plastica riciclata a contatto con gli alimenti.",
      url: "https://www.gazzettaufficiale.it/eli/id/2026/10/30/26G00217/SG",
      published_on: ~D[2026-10-30]
    ]
    |> Keyword.merge(attrs)
    |> Act.new()
  end

  def ministerial_decree(attrs \\ []) do
    [
      code: "26A05686",
      heading: "DECRETO 20 ottobre 2026",
      issuer: "MINISTERO DELL'ECONOMIA E DELLE FINANZE",
      title: "Misure del diritto speciale sulla benzina nel territorio di Livigno.",
      url: "https://www.gazzettaufficiale.it/eli/id/2026/10/31/26A05686/SG",
      published_on: ~D[2026-10-31]
    ]
    |> Keyword.merge(attrs)
    |> Act.new()
  end

  def fixture(name), do: File.read!(Path.join([__DIR__, "fixtures", "gazzetta", name]))
end
