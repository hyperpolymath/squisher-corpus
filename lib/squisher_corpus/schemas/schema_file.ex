# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Schemas.SchemaFile do
  @moduledoc """
  Ecto schema for discovered schema files from GitHub.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @formats ~w(protobuf avro thrift jsonschema pydantic serde capnproto flatbuffers messagepack graphql openapi bebop rescript)

  schema "schema_files" do
    field :path, :string
    field :format, :string
    field :sha, :string
    field :raw_content, :string
    field :size_bytes, :integer

    belongs_to :github_repo, SquisherCorpus.Schemas.GithubRepo
    has_one :analysis_result, SquisherCorpus.Schemas.AnalysisResult

    timestamps(type: :utc_datetime)
  end

  def changeset(schema_file, attrs) do
    schema_file
    |> cast(attrs, [:path, :format, :sha, :raw_content, :size_bytes, :github_repo_id])
    |> validate_required([:path, :format, :sha, :github_repo_id])
    |> validate_inclusion(:format, @formats)
    |> unique_constraint(:sha)
    |> foreign_key_constraint(:github_repo_id)
  end

  def formats, do: @formats
end
