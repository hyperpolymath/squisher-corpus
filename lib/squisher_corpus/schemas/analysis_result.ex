# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Schemas.AnalysisResult do
  @moduledoc """
  Ecto schema for protocol-squisher analysis results.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "analysis_results" do
    field :ir_schema, :map
    field :squishability_score, :float
    field :transport_classes, {:array, :string}
    field :field_count, :integer
    field :type_diversity, :integer

    belongs_to :schema_file, SquisherCorpus.Schemas.SchemaFile

    timestamps(type: :utc_datetime)
  end

  def changeset(result, attrs) do
    result
    |> cast(attrs, [
      :ir_schema,
      :squishability_score,
      :transport_classes,
      :field_count,
      :type_diversity,
      :schema_file_id
    ])
    |> validate_required([:schema_file_id, :squishability_score])
    |> validate_number(:squishability_score, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> foreign_key_constraint(:schema_file_id)
    |> unique_constraint(:schema_file_id)
  end
end
