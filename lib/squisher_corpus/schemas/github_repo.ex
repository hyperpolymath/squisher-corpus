# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Schemas.GithubRepo do
  @moduledoc """
  Ecto schema for tracked GitHub repositories.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "github_repos" do
    field :owner, :string
    field :name, :string
    field :stars, :integer, default: 0
    field :language, :string
    field :last_crawled_at, :utc_datetime

    has_many :schema_files, SquisherCorpus.Schemas.SchemaFile

    timestamps(type: :utc_datetime)
  end

  def changeset(repo, attrs) do
    repo
    |> cast(attrs, [:owner, :name, :stars, :language, :last_crawled_at])
    |> validate_required([:owner, :name])
    |> unique_constraint([:owner, :name])
  end
end
