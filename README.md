# Gazzetta per tutti

The new Italian laws, explained simply. Every few hours the app reads the latest
issues of the Gazzetta Ufficiale (Serie Generale), stores the new acts and asks
a language model (gpt-4o-mini by default) to explain each of them in a few plain sentences.

## Setup

  * Start Postgres (e.g. `docker run -d --name gazzetta-postgres -e POSTGRES_PASSWORD=postgres -p 127.0.0.1:5432:5432 postgres:18.6`)
  * Run `mix setup`
  * Export `OPENAI_API_KEY` (optionally `OPENAI_MODEL`, default `gpt-4o-mini`), then start the app with `mix phx.server`
  * To use Claude instead, export `SUMMARIZER=claude` and `ANTHROPIC_API_KEY`

Visit [`localhost:4000`](http://localhost:4000). The first check of the Gazzetta
runs 10 seconds after boot, then every 3 hours (`config :gazzetta_per_tutti, scheduler:`).

## Structure

The domain lives in `lib/gazzetta_per_tutti` and reaches the outside world only
through ports (behaviours), whose adapters are chosen in config:

| Port | Adapter | |
|---|---|---|
| `Gazzetta` | `Gazzetta.Website` | Issue and act pages of gazzettaufficiale.it (last 3 issues) |
| `Summarizer` | `Summarizer.OpenAI` (default) | gpt-4o-mini via Chat Completions |
| | `Summarizer.Claude` | Claude Haiku 5.5 via the Messages API |
| `ActRepository` | `ActRepository.Postgres` | Ecto |

## Running tests

```bash
mix test
```

Tests describe behaviour through the public API (`GazzettaPerTutti`) and the
LiveView, with the Gazzetta and the summarizer mocked and a real database.
Adapters are tested against responses recorded from the real website.

## Deploy

Pushes to `main` run the tests and push `ghcr.io/mircoporetti/gazzetta-per-tutti:<timestamp>-<sha>`
(`.github/workflows/deploy.yml`). Flux in the cluster (configured in the `homelab`
repo, `clusters/hogwarts-kitchen/gazzetta`) picks up the new tag, commits it to
`k8s/app` and applies it. Migrations run in an init container.

Secrets are applied by hand once: copy `k8s/app/secrets.example.yaml` to
`k8s/app/secrets.yaml` (gitignored), fill it in, `kubectl apply -f k8s/app/secrets.yaml`.
