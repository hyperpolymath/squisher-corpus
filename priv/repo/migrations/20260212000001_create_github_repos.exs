# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Repo.Migrations.CreateGithubRepos do
  use Ecto.Migration

  def change do
    create table(:github_repos) do
      add :owner, :string, null: false
      add :name, :string, null: false
      add :stars, :integer, default: 0
      add :language, :string
      add :last_crawled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:github_repos, [:owner, :name])
    create index(:github_repos, [:stars])
    create index(:github_repos, [:language])
  end
end
