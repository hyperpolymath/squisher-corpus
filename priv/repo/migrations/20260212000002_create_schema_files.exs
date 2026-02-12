# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Repo.Migrations.CreateSchemaFiles do
  use Ecto.Migration

  def change do
    create table(:schema_files) do
      add :github_repo_id, references(:github_repos, on_delete: :delete_all), null: false
      add :path, :string, null: false
      add :format, :string, null: false
      add :sha, :string, null: false
      add :raw_content, :text
      add :size_bytes, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:schema_files, [:sha])
    create index(:schema_files, [:github_repo_id])
    create index(:schema_files, [:format])
  end
end
