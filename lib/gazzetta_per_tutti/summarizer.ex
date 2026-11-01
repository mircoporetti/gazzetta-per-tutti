defmodule GazzettaPerTutti.Summarizer do
  @moduledoc false

  alias GazzettaPerTutti.Act

  @callback summarize(Act.t(), full_text :: String.t()) :: {:ok, String.t()} | {:error, term()}
end
