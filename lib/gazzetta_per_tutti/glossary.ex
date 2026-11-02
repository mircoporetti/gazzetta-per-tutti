defmodule GazzettaPerTutti.Glossary do
  @moduledoc """
  Plain-language definitions of the terms readers meet on act cards.

  Hand-written on purpose: definitions must be exact and stable, unlike the
  AI-generated explanations.
  """

  alias GazzettaPerTutti.Act

  @type term_entry :: %{id: String.t(), term: String.t(), definition: String.t()}

  @act_types [
    {"legge",
     "Una regola approvata dal Parlamento, cioè da Camera e Senato. È la forma più classica di norma."},
    {"legge costituzionale",
     "Una legge che cambia o completa la Costituzione. Il Parlamento deve approvarla due volte, a distanza di almeno tre mesi."},
    {"decreto-legge",
     "Una regola fatta dal Governo quando c'è urgenza. Vale da subito, ma il Parlamento deve confermarla entro 60 giorni, altrimenti decade come se non fosse mai esistita."},
    {"decreto legislativo",
     "Una regola scritta dal Governo su incarico del Parlamento, che prima ha fissato con una legge i temi e i limiti da rispettare. Ha la stessa forza di una legge."},
    {"decreto del presidente della repubblica",
     "Un atto firmato dal Presidente della Repubblica, di solito su proposta del Governo. Spesso serve per regolamenti, nomine o per sciogliere i consigli comunali."},
    {"decreto del presidente del consiglio dei ministri",
     "Un atto firmato dal Presidente del Consiglio (spesso chiamato DPCM). Serve a mettere in pratica leggi già esistenti, per esempio dividendo fondi o organizzando uffici."},
    {"decreto ministeriale",
     "Un atto di un singolo ministero. Mette in pratica una legge nei dettagli: importi, moduli, scadenze, elenchi."},
    {"decreto",
     "Un atto con cui un'autorità pubblica (un ministero, un commissario, un ente) decide qualcosa nel suo campo, applicando leggi già esistenti."},
    {"delibera",
     "Una decisione presa da un organo che vota insieme, come un comitato, un'autorità o un consiglio. Spesso riguarda fondi, tariffe o progetti."},
    {"determina",
     "Una decisione presa da un ufficio o da un'agenzia pubblica. Per esempio l'Agenzia del farmaco la usa per autorizzare un medicinale o fissarne il prezzo."},
    {"ordinanza",
     "Un ordine dato da un'autorità per affrontare una situazione precisa, spesso un'emergenza come un terremoto o un'alluvione."},
    {"provvedimento", "Una decisione di un'autorità pubblica su un caso o un tema specifico."},
    {"regolamento",
     "Un insieme di regole di dettaglio che dice come applicare una legge in pratica."},
    {"comunicato",
     "Un avviso ufficiale. Di solito non crea regole nuove: informa di qualcosa già deciso, come l'autorizzazione di un farmaco, una nomina o una correzione."}
  ]

  @general [
    {"gazzetta-ufficiale", "Gazzetta Ufficiale",
     "Il giornale ufficiale dello Stato italiano. Le nuove norme vengono pubblicate qui, e di solito è proprio la pubblicazione a renderle valide."},
    {"leggi-e-atti-normativi", "Leggi e atti normativi",
     "Gli atti che creano regole valide per tutti: leggi, decreti-legge, decreti legislativi e alcuni regolamenti. Sono quelli che mostriamo di default."},
    {"entrata-in-vigore", "Entrata in vigore",
     "Il giorno da cui una norma comincia a valere. Se l'atto non dice altro, di solito è 15 giorni dopo la pubblicazione nella Gazzetta Ufficiale."}
  ]

  @definitions Map.new(@act_types)

  @doc "The definition of an act's type, or nil when the type is not in the glossary."
  @spec act_type(Act.t()) :: String.t() | nil
  def act_type(%Act{type: type}) when is_binary(type), do: @definitions[String.downcase(type)]
  def act_type(%Act{}), do: nil

  @doc "Every term, for the glossary page: general terms first, then act types."
  @spec entries() :: [term_entry()]
  def entries do
    general = for {id, term, definition} <- @general, do: entry(id, term, definition)

    act_types =
      for {term, definition} <- @act_types,
          do: entry(slug(term), String.capitalize(term), definition)

    general ++ act_types
  end

  @doc "The anchor of an act type on the glossary page."
  @spec act_type_anchor(Act.t()) :: String.t()
  def act_type_anchor(%Act{type: type}), do: slug(type)

  defp entry(id, term, definition), do: %{id: id, term: term, definition: definition}

  defp slug(term), do: term |> String.downcase() |> String.replace(~r/[^a-z]+/, "-")
end
