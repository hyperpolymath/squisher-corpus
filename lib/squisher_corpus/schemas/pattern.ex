# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Schemas.Pattern do
  @moduledoc """
  Ecto schema for discovered cross-schema patterns.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @pattern_types ~w(
    safe_widening unnecessary_option overprecision_float string_enum
    repeated_copyable unnecessary_nesting deprecated zero_copy
    format_prevalence type_distribution nesting_depth optional_ratio
    cross_format_pair field_name_pattern
  )

  schema "patterns" do
    field :pattern_type, :string
    field :frequency, :integer, default: 0
    field :description, :string
    field :representative_schemas, {:array, :integer}
    field :confidence, :float

    timestamps(type: :utc_datetime)
  end

  def changeset(pattern, attrs) do
    pattern
    |> cast(attrs, [:pattern_type, :frequency, :description, :representative_schemas, :confidence])
    |> validate_required([:pattern_type, :frequency])
    |> validate_inclusion(:pattern_type, @pattern_types)
    |> validate_number(:confidence, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
  end

  def pattern_types, do: @pattern_types
end
