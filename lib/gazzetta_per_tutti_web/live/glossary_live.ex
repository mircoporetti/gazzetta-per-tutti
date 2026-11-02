defmodule GazzettaPerTuttiWeb.GlossaryLive do
  use GazzettaPerTuttiWeb, :live_view

  alias GazzettaPerTutti.Glossary

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Glossario")
     |> assign(:entries, Glossary.entries())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section class="mb-10">
        <.link
          id="back-to-acts"
          navigate={~p"/"}
          class="mb-6 inline-flex items-center gap-1 text-sm font-medium text-stone-500 transition hover:text-stone-900 dark:text-stone-400 dark:hover:text-stone-100"
        >
          <.icon name="hero-arrow-left-mini" class="size-4" /> Torna alle norme
        </.link>
        <h1 class="font-serif text-4xl sm:text-5xl font-semibold tracking-tight text-stone-900 dark:text-stone-50">
          Glossario
        </h1>
        <p class="mt-4 text-lg leading-relaxed text-stone-600 dark:text-stone-300">
          Le parole che trovi nella Gazzetta Ufficiale, spiegate in poche righe.
        </p>
      </section>

      <dl id="glossary" class="space-y-4">
        <div
          :for={entry <- @entries}
          id={entry.id}
          class="scroll-mt-24 rounded-2xl border border-stone-200 bg-white p-6 shadow-sm transition target:border-emerald-300 target:ring-2 target:ring-emerald-200 dark:border-stone-800 dark:bg-stone-900 dark:target:border-emerald-700 dark:target:ring-emerald-900"
        >
          <dt class="font-serif text-lg font-semibold text-stone-900 dark:text-stone-100">
            {entry.term}
          </dt>
          <dd class="mt-1 leading-relaxed text-stone-700 dark:text-stone-300">{entry.definition}</dd>
        </div>
      </dl>
    </Layouts.app>
    """
  end
end
