defmodule GazzettaPerTutti.Summarizer.Claude do
  @moduledoc false
  @behaviour GazzettaPerTutti.Summarizer

  alias GazzettaPerTutti.Act
  alias GazzettaPerTutti.Summarizer.Prompt

  @model "claude-haiku-5-5"
  @api_version "2026-10-21"

  @impl true
  def summarize(%Act{} = act, full_text) do
    case config(:api_key) do
      key when key in [nil, ""] -> {:error, :missing_api_key}
      key -> request_summary(key, act, full_text)
    end
  end

  defp request_summary(api_key, act, full_text) do
    body = %{
      model: @model,
      # Thinking counts towards max_tokens.
      max_tokens: 4_000,
      output_config: %{effort: "low"},
      system: Prompt.system(),
      messages: [%{role: "user", content: Prompt.user_message(act, full_text)}]
    }

    [
      base_url: "https://api.anthropic.com",
      url: "/v1/messages",
      headers: [{"x-api-key", api_key}, {"anthropic-version", @api_version}],
      json: body,
      receive_timeout: 120_000,
      retry: :transient
    ]
    |> Req.new()
    |> Req.merge(config(:req_options, []))
    |> Req.post()
    |> handle_response()
  end

  defp handle_response(
         {:ok, %Req.Response{status: 200, body: %{"stop_reason" => "end_turn"} = body}}
       ) do
    body["content"]
    |> Enum.filter(&(&1["type"] == "text"))
    |> Enum.map_join("\n", & &1["text"])
    |> String.trim()
    |> case do
      "" -> {:error, :empty_summary}
      summary -> {:ok, summary}
    end
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: %{"stop_reason" => reason}}}),
    do: {:error, {:stop_reason, reason}}

  defp handle_response({:ok, %Req.Response{status: status, body: body}}),
    do: {:error, {:http_status, status, body}}

  defp handle_response({:error, exception}), do: {:error, exception}

  defp config(key, default \\ nil) do
    :gazzetta_per_tutti
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, default)
  end
end
