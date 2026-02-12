# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Repo.Migrations.CreateAnalysisResults do
  use Ecto.Migration

  def change do
    create table(:analysis_results) do
      add :schema_file_id, references(:schema_files, on_delete: :delete_all), null: false
      add :ir_schema, :text
      add :squishability_score, :float
      add :transport_classes, :text
      add :field_count, :integer
      add :type_diversity, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:analysis_results, [:schema_file_id])
    create index(:analysis_results, [:squishability_score])
  end
end
