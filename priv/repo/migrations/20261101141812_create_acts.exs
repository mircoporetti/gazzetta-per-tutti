defmodule GazzettaPerTutti.Repo.Migrations.CreateActs do
  use Ecto.Migration

  def change do
    create table(:acts, primary_key: false) do
      add :code, :string, primary_key: true
      add :heading, :text, null: false
      add :issuer, :text
      add :type, :string, null: false
      add :title, :text, null: false
      add :url, :string, null: false
      add :law, :boolean, null: false, default: false
      add :published_on, :date, null: false
      add :summary, :text
      add :summarized_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:acts, [:published_on, :code])

    create index(:acts, [:published_on],
             where: "summary IS NULL",
             name: :acts_waiting_for_summary_index
           )
  end
end
