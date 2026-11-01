defmodule GazzettaPerTutti.Summarizer.OpenAITest do
  use ExUnit.Case, async: true

  import GazzettaPerTutti.ActsFixtures, only: [law: 0]

  alias GazzettaPerTutti.Summarizer.OpenAI

  defp openai_replies(status \\ 200, body) do
    test_pid = self()

    Req.Test.stub(OpenAI, fn conn ->
      {:ok, raw, conn} = Plug.Conn.read_body(conn)
      send(test_pid, {:request, conn, Jason.decode!(raw)})
      conn |> Plug.Conn.put_status(status) |> Req.Test.json(body)
    end)
  end

  defp reply(content, finish_reason \\ "stop", refusal \\ nil) do
    %{
      "choices" => [
        %{
          "index" => 0,
          "finish_reason" => finish_reason,
          "message" => %{"role" => "assistant", "content" => content, "refusal" => refusal}
        }
      ]
    }
  end

  test "returns the explanation written by the model" do
    openai_replies(reply("  Cambiano le regole per la plastica riciclata.\n"))

    assert {:ok, "Cambiano le regole per la plastica riciclata."} =
             OpenAI.summarize(law(), "Art. 1 ...")
  end

  test "sends the act's text to gpt-4o-mini, authenticated" do
    openai_replies(reply("Spiegazione"))

    OpenAI.summarize(law(), "Art. 1 Il testo della legge")

    assert_received {:request, conn, body}
    assert conn.request_path == "/v1/chat/completions"
    assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test-api-key"]
    assert body["model"] == "gpt-4o-mini"
    assert Enum.any?(body["messages"], &(&1["content"] =~ "Art. 1 Il testo della legge"))
  end

  test "an incomplete answer is not used as an explanation" do
    openai_replies(reply("Cambiano le", "length"))

    assert {:error, {:finish_reason, "length"}} = OpenAI.summarize(law(), "testo")
  end

  test "a refusal is not used as an explanation" do
    openai_replies(reply(nil, "stop", "I can't help with that."))

    assert {:error, :refusal} = OpenAI.summarize(law(), "testo")
  end

  test "reports API errors" do
    openai_replies(429, %{"error" => %{"type" => "rate_limit_exceeded"}})

    assert {:error, {:http_status, 429, _body}} = OpenAI.summarize(law(), "testo")
  end
end
