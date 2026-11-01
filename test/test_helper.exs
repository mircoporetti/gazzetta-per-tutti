Mox.defmock(GazzettaPerTutti.GazzettaMock, for: GazzettaPerTutti.Gazzetta)
Mox.defmock(GazzettaPerTutti.SummarizerMock, for: GazzettaPerTutti.Summarizer)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(GazzettaPerTutti.Repo, :manual)
