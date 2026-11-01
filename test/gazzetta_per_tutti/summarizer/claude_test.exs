defmodule GazzettaPerTutti.Summarizer.ClaudeTest do
  use ExUnit.Case, async: true

  import GazzettaPerTutti.ActsFixtures, only: [law: 0]

  alias GazzettaPerTutti.Summarizer.Claude

  defp claude_replies(status \\ 200, body) do
    test_pid = self()

    Req.Test.stub(Claude, fn conn ->
      {:ok, raw, conn} = Plug.Conn.read_body(conn)
      send(test_pid, {:request, conn, Jason.decode!(raw)})
      conn |> Plug.Conn.put_status(status) |> Req.Test.json(body)
    end)
  end

  defp reply(text, stop_reason \\ "end_turn") do
    %{
      "content" => [
        %{"type" => "thinking", "thinking" => ""},
        %{"type" => "text", "text" => text}
      ],
      "stop_reason" => stop_reason
    }
  end

  test "returns the explanation written by Claude" do
    claude_replies(reply("  Cambiano le regole per la plastica riciclata.\n"))

    assert {:ok, "Cambiano le regole per la plastica riciclata."} =
             Claude.summarize(law(), "Art. 1 ...")
  end

  test "sends the act's text to Claude Haiku, authenticated" do
    claude_replies(reply("Spiegazione"))

    Claude.summarize(law(), "Art. 1 Il testo della legge")

    assert_received {:request, conn, body}
    assert conn.request_path == "/v1/messages"
    assert Plug.Conn.get_req_header(conn, "x-api-key") == ["test-api-key"]
    assert Plug.Conn.get_req_header(conn, "anthropic-version") == ["2026-10-21"]
    assert %{"model" => "claude-haiku-5-5", "output_config" => %{"effort" => "low"}} = body
    assert [%{"role" => "user", "content" => content}] = body["messages"]
    assert content =~ "Art. 1 Il testo della legge"
  end

  test "an incomplete answer is not used as an explanation" do
    claude_replies(reply("Cambiano le", "max_tokens"))

    assert {:error, {:stop_reason, "max_tokens"}} = Claude.summarize(law(), "testo")
  end

  test "a refusal is not used as an explanation" do
    claude_replies(%{"content" => [], "stop_reason" => "refusal"})

    assert {:error, {:stop_reason, "refusal"}} = Claude.summarize(law(), "testo")
  end

  test "reports API errors" do
    claude_replies(529, %{"type" => "error", "error" => %{"type" => "overloaded_error"}})

    assert {:error, {:http_status, 529, _body}} = Claude.summarize(law(), "testo")
  end
end
