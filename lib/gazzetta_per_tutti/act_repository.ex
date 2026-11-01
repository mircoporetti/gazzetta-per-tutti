defmodule GazzettaPerTutti.ActRepository do
  @moduledoc false

  alias GazzettaPerTutti.Act

  @doc "Stores only the acts not stored yet, atomically, and returns them."
  @callback insert_new([Act.t()]) :: [Act.t()]

  @callback save_summary(Act.t()) :: Act.t()

  @callback list_unsummarized(limit :: pos_integer()) :: [Act.t()]

  @callback list(keyword()) :: [Act.t()]
end
