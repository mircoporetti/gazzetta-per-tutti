defmodule GazzettaPerTutti.Gazzetta do
  @moduledoc false

  alias GazzettaPerTutti.Act

  @callback recent_acts() :: {:ok, [Act.t()]} | {:error, term()}

  @callback full_text(Act.t()) :: {:ok, String.t()} | {:error, term()}
end
