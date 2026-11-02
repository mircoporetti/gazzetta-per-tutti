defmodule GazzettaPerTuttiWeb.ActsLive do
  use GazzettaPerTuttiWeb, :live_view

  alias GazzettaPerTutti.Act
  alias GazzettaPerTutti.Glossary

  @page_size 20
  @months ~w(gennaio febbraio marzo aprile maggio giugno luglio agosto settembre ottobre novembre dicembre)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: GazzettaPerTutti.subscribe()

    {:ok,
     socket
     |> assign(:page_title, "Le nuove norme, spiegate semplici")
     |> stream_configure(:acts, dom_id: &"act-#{&1.code}")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    only_laws = params["atti"] != "tutti"

    {:noreply,
     socket
     |> assign(only_laws: only_laws, offset: 0)
     |> load_page(reset: true)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    {:noreply,
     socket
     |> update(:offset, &(&1 + @page_size))
     |> load_page(reset: false)}
  end

  @impl true
  def handle_info({:act_published, %Act{} = act}, socket) do
    if visible?(act, socket) do
      {:noreply, socket |> stream_insert(:acts, act, at: 0) |> assign(:empty?, false)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:act_explained, %Act{} = act}, socket) do
    {:noreply, stream_insert(socket, :acts, act, update_only: true)}
  end

  defp visible?(act, socket), do: act.law or not socket.assigns.only_laws

  defp load_page(socket, reset: reset) do
    %{offset: offset, only_laws: only_laws} = socket.assigns

    # One more than needed tells whether another page exists.
    acts =
      GazzettaPerTutti.list_acts(limit: @page_size + 1, offset: offset, only_laws: only_laws)

    socket
    |> assign(:more?, length(acts) > @page_size)
    |> assign(:empty?, reset and acts == [])
    |> stream(:acts, Enum.take(acts, @page_size), reset: reset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section class="mb-10">
        <h1 class="font-serif text-4xl sm:text-5xl font-semibold tracking-tight text-stone-900 dark:text-stone-50">
          Le nuove norme,
          <span class="italic text-emerald-700 dark:text-emerald-400">spiegate semplici</span>
        </h1>
        <p class="mt-4 text-lg leading-relaxed text-stone-600 dark:text-stone-300">
          Ogni giorno leggiamo la Gazzetta Ufficiale e spieghiamo in poche righe cosa cambia,
          senza giuridichese.
        </p>
      </section>

      <nav
        id="acts-filter"
        aria-label="Filtra gli atti"
        class="mb-8 inline-flex rounded-full bg-stone-200/70 p-1 dark:bg-stone-800"
      >
        <.filter_link id="filter-laws" patch={~p"/"} active={@only_laws}>Leggi e atti normativi</.filter_link>
        <.filter_link id="filter-all" patch={~p"/?atti=tutti"} active={not @only_laws}>Tutti gli atti</.filter_link>
      </nav>

      <div
        :if={@empty?}
        id="acts-empty"
        class="rounded-2xl border border-dashed border-stone-300 p-10 text-center text-stone-500 dark:border-stone-700 dark:text-stone-400"
      >
        <.icon name="hero-newspaper" class="mx-auto mb-3 size-8 opacity-60" />
        <p>Non ci sono ancora atti da mostrare.</p>
        <p class="mt-1 text-sm">
          Controlliamo la Gazzetta Ufficiale più volte al giorno: torna a dare un'occhiata più tardi.
        </p>
      </div>

      <ol id="acts" phx-update="stream" class="space-y-5">
        <li :for={{dom_id, act} <- @streams.acts} id={dom_id}>
          <.act_card act={act} />
        </li>
      </ol>

      <div :if={@more?} class="mt-10 text-center">
        <button
          id="load-more"
          phx-click="load_more"
          class="rounded-full border border-stone-300 px-6 py-2.5 text-sm font-medium text-stone-700 transition hover:border-stone-400 hover:bg-white hover:shadow-sm phx-click-loading:opacity-60 dark:border-stone-700 dark:text-stone-200 dark:hover:bg-stone-800"
        >
          Mostra atti precedenti
        </button>
      </div>

      <p class="mt-14 border-t border-stone-200 pt-6 text-xs leading-relaxed text-stone-500 dark:border-stone-800 dark:text-stone-400">
        Le spiegazioni sono generate automaticamente da un'intelligenza artificiale e possono contenere
        imprecisioni. Fa fede solo il testo pubblicato nella Gazzetta Ufficiale.
        Non conosci una parola? <.link
          id="glossary-link"
          navigate={~p"/glossario"}
          class="font-medium text-emerald-700 underline-offset-2 hover:underline dark:text-emerald-400"
        >
          Leggi il glossario
        </.link>.
      </p>
    </Layouts.app>
    """
  end

  attr :id, :string, required: true
  attr :patch, :string, required: true
  attr :active, :boolean, required: true
  slot :inner_block, required: true

  defp filter_link(assigns) do
    ~H"""
    <.link
      id={@id}
      patch={@patch}
      aria-current={@active && "page"}
      class={[
        "rounded-full px-4 py-1.5 text-sm font-medium transition",
        if(@active,
          do: "bg-white text-stone-900 shadow-sm dark:bg-stone-950 dark:text-stone-50",
          else: "text-stone-600 hover:text-stone-900 dark:text-stone-400 dark:hover:text-stone-100"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :act, Act, required: true

  defp act_card(assigns) do
    ~H"""
    <article class={[
      "group rounded-2xl border bg-white p-6 shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md dark:bg-stone-900",
      if(@act.law,
        do: "border-emerald-200 dark:border-emerald-900/60",
        else: "border-stone-200 dark:border-stone-800"
      )
    ]}>
      <header class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs">
        <.act_type act={@act} />
        <time datetime={Date.to_iso8601(@act.published_on)} class="text-stone-500 dark:text-stone-400">
          {format_date(@act.published_on)}
        </time>
      </header>

      <p :if={@act.issuer} class="mt-3 text-xs font-medium uppercase tracking-wide text-stone-400">
        {String.capitalize(@act.issuer)}
      </p>
      <h2 class="mt-1 font-serif text-lg font-semibold leading-snug text-stone-900 dark:text-stone-100">
        {@act.title}
      </h2>

      <%= if @act.summary do %>
        <p class="act-summary mt-4 leading-relaxed text-stone-700 dark:text-stone-300">
          {@act.summary}
        </p>
      <% else %>
        <p class="act-summary-pending mt-4 flex items-center gap-2 text-sm italic text-stone-400">
          <.icon name="hero-sparkles" class="size-4 motion-safe:animate-pulse" />
          Stiamo preparando la spiegazione…
        </p>
      <% end %>

      <a
        href={@act.url}
        target="_blank"
        rel="noopener noreferrer"
        class="act-source mt-5 inline-flex items-center gap-1 text-sm font-medium text-emerald-700 hover:text-emerald-900 dark:text-emerald-400 dark:hover:text-emerald-300"
      >
        Leggi il testo ufficiale
        <.icon
          name="hero-arrow-up-right-mini"
          class="size-4 transition group-hover:translate-x-0.5 group-hover:-translate-y-0.5"
        />
        <span class="sr-only">(si apre in una nuova scheda)</span>
      </a>
    </article>
    """
  end

  attr :act, Act, required: true

  defp act_type(assigns) do
    assigns = assign(assigns, :definition, Glossary.act_type(assigns.act))

    ~H"""
    <%= if @definition do %>
      <%!-- Clicking outside or pressing Escape closes the definition --%>
      <details
        id={"act-type-#{@act.code}"}
        class="act-type group/term relative"
        phx-click-away={JS.remove_attribute("open")}
        phx-window-keydown={JS.remove_attribute("open")}
        phx-key="Escape"
      >
        <summary class={[
          act_type_badge_class(@act),
          "inline-flex cursor-pointer list-none items-center gap-1 transition hover:ring-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600 [&::-webkit-details-marker]:hidden",
          if(@act.law,
            do: "hover:ring-emerald-200 dark:hover:ring-emerald-800",
            else: "hover:ring-stone-200 dark:hover:ring-stone-700"
          )
        ]}>
          {@act.type}
          <.icon name="hero-question-mark-circle-mini" class="size-3.5 opacity-60" />
          <span class="sr-only">: che cos'è?</span>
        </summary>
        <div class="act-type-definition absolute left-0 top-full z-10 mt-2 w-80 max-w-[calc(100vw-4rem)] rounded-xl border border-stone-200 bg-white p-4 text-sm normal-case leading-relaxed tracking-normal text-stone-700 shadow-lg motion-safe:transition dark:border-stone-700 dark:bg-stone-800 dark:text-stone-200">
          <p class="font-semibold text-stone-900 dark:text-stone-50">{@act.type}</p>
          <p class="mt-1">{@definition}</p>
          <.link
            navigate={~p"/glossario##{Glossary.act_type_anchor(@act)}"}
            class="mt-2 inline-block text-xs font-medium text-emerald-700 hover:underline dark:text-emerald-400"
          >
            Altre parole nel glossario
          </.link>
        </div>
      </details>
    <% else %>
      <span class={act_type_badge_class(@act)}>{@act.type}</span>
    <% end %>
    """
  end

  defp act_type_badge_class(act) do
    [
      "act-type-badge rounded-full px-2.5 py-0.5 font-semibold uppercase tracking-wide",
      if(act.law,
        do: "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/50 dark:text-emerald-300",
        else: "bg-stone-100 text-stone-600 dark:bg-stone-800 dark:text-stone-300"
      )
    ]
  end

  defp format_date(%Date{day: day, month: month, year: year}),
    do: "#{day} #{Enum.at(@months, month - 1)} #{year}"
end
