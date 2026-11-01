defmodule GazzettaPerTutti.Summarizer.Prompt do
  alias GazzettaPerTutti.Act

  # ~30k tokens: caps the cost of huge acts like the budget law.
  @max_text_length 120_000

  @system """
  Spieghi le nuove norme italiane a persone senza alcuna formazione giuridica.
  Ricevi un atto pubblicato nella Gazzetta Ufficiale e scrivi una spiegazione \
  di 2-4 frasi brevi, in italiano semplice, che dica:
  - cosa cambia, in concreto;
  - chi riguarda;
  - da quando vale, se il testo lo dice.

  Usa parole di tutti i giorni: niente gergo legale, niente rimandi a commi, \
  articoli o altre leggi. Non usare elenchi, titoli o markdown: solo testo semplice.
  Se l'atto riguarda solo un caso specifico (una nomina, una singola azienda, \
  un comune), dillo in una frase.
  Basati solo sul testo fornito. Se un'informazione non c'è, non inventarla.
  """

  def system, do: @system

  def user_message(%Act{} = act, full_text) do
    """
    Tipo di atto: #{act.heading}
    Emesso da: #{act.issuer || "non indicato"}
    Titolo ufficiale: #{act.title}

    Testo dell'atto:
    #{bounded(full_text)}
    """
  end

  defp bounded(""), do: "(testo non disponibile: basati sul titolo)"

  defp bounded(text) do
    if String.length(text) > @max_text_length do
      String.slice(text, 0, @max_text_length) <>
        "\n[...il testo continua: spiega le parti principali che hai letto]"
    else
      text
    end
  end
end
