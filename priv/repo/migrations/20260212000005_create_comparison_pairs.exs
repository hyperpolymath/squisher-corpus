# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Repo.Migrations.CreateComparisonPairs do
  use Ecto.Migration

  def change do
    create table(:comparison_pairs) do
      add :source_id, references(:schema_files, on_delete: :delete_all), null: false
      add :target_id, references(:schema_files, on_delete: :delete_all), null: false
      add :forward_class, :string, null: false
      add :reverse_class, :string, null: false
      add :asymmetry_score, :float

      timestamps(type: :utc_datetime)
    end

    create unique_index(:comparison_pairs, [:source_id, :target_id])
    create index(:comparison_pairs, [:forward_class])
    create index(:comparison_pairs, [:asymmetry_score])
  end
end
