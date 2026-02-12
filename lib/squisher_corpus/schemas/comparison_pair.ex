# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Schemas.ComparisonPair do
  @moduledoc """
  Ecto schema for schema-to-schema comparison pairs.
  Tracks forward/reverse transport class compatibility.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "comparison_pairs" do
    field :forward_class, :string
    field :reverse_class, :string
    field :asymmetry_score, :float

    belongs_to :source, SquisherCorpus.Schemas.SchemaFile
    belongs_to :target, SquisherCorpus.Schemas.SchemaFile

    timestamps(type: :utc_datetime)
  end

  def changeset(pair, attrs) do
    pair
    |> cast(attrs, [:forward_class, :reverse_class, :asymmetry_score, :source_id, :target_id])
    |> validate_required([:source_id, :target_id, :forward_class, :reverse_class])
    |> validate_number(:asymmetry_score, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> foreign_key_constraint(:source_id)
    |> foreign_key_constraint(:target_id)
    |> unique_constraint([:source_id, :target_id])
  end
end
