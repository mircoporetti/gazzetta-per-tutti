defmodule GazzettaPerTutti.Summarizer.OpenAI do
  @moduledoc false
  @behaviour GazzettaPerTutti.Summarizer

  alias GazzettaPerTutti.Act
  alias GazzettaPerTutti.Summarizer.Prompt

  @default_model "gpt-4o-mini"

  @impl true
  def summarize(%Act{} = act, full_text) do
    case config(:api_key) do
      key when key in [nil, ""] -> {:error, :missing_api_key}
      key -> request_summary(key, act, full_text)
    end
  end

  defp request_summary(api_key, act, full_text) do
    body = %{
      model: config(:model) || @default_model,
      max_tokens: 500,
      temperature: 0.2,
      messages: [
        %{role: "system", content: Prompt.system()},
        %{role: "user", content: Prompt.user_message(act, full_text)}
      ]
    }

    [
      base_url: "https://api.openai.com",
      url: "/v1/chat/completions",
      auth: {:bearer, api_key},
      json: body,
      receive_timeout: 120_000,
      retry: :transient
    ]
    |> Req.new()
    |> Req.merge(config(:req_options, []))
    |> Req.post()
    |> handle_response()
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: %{"choices" => [choice | _]}}}) do
    case choice do
      %{"finish_reason" => "stop", "message" => %{"refusal" => refusal}}
      when is_binary(refusal) ->
        {:error, :refusal}

      %{"finish_reason" => "stop", "message" => %{"content" => content}}
      when is_binary(content) ->
        case String.trim(content) do
          "" -> {:error, :empty_summary}
          summary -> {:ok, summary}
        end

      %{"finish_reason" => reason} ->
        {:error, {:finish_reason, reason}}
    end
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}}),
    do: {:error, {:http_status, status, body}}

  defp handle_response({:error, exception}), do: {:error, exception}

  defp config(key, default \\ nil) do
    :gazzetta_per_tutti
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, default)
  end
end
