defmodule GazzettaPerTutti.Summarizer.PromptTest do
  use ExUnit.Case, async: true

  import GazzettaPerTutti.ActsFixtures, only: [law: 0]

  alias GazzettaPerTutti.Summarizer.Prompt

  test "the model is told which act it is explaining, with its text" do
    message = Prompt.user_message(law(), "Art. 1 Il testo della legge")

    assert message =~ "DECRETO LEGISLATIVO 9 ottobre 2026, n. 199"
    assert message =~ law().title
    assert message =~ "Art. 1 Il testo della legge"
  end

  test "a huge act is sent bounded, to keep the cost capped" do
    huge_text = String.duplicate("parola ", 150_000)

    message = Prompt.user_message(law(), huge_text)

    assert String.length(message) < div(String.length(huge_text), 4)
  end
end
