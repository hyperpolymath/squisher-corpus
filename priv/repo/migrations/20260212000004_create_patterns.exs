# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Repo.Migrations.CreatePatterns do
  use Ecto.Migration

  def change do
    create table(:patterns) do
      add :pattern_type, :string, null: false
      add :frequency, :integer, null: false, default: 0
      add :description, :text
      add :representative_schemas, :text
      add :confidence, :float

      timestamps(type: :utc_datetime)
    end

    create index(:patterns, [:pattern_type])
    create index(:patterns, [:frequency])
  end
end
