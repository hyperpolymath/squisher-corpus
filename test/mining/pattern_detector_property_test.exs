# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Mining.PatternDetectorPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias SquisherCorpus.Mining.PatternDetector

  # Generator for fake analysis results (struct-like maps)
  defp analysis_result_gen do
    gen all(
          format <- member_of(["protobuf", "avro", "thrift", "serde", "pydantic"]),
          score <- float(min: 0.0, max: 1.0),
          field_count <- integer(0..50),
          classes <- list_of(member_of(["Concorde", "Business", "Economy", "Wheelbarrow"]), min_length: 0, max_length: 5),
          fields <- list_of(field_gen(), min_length: 0, max_length: 10)
        ) do
      %{
        schema_file: %{
          format: format,
          github_repo_id: :rand.uniform(100)
        },
        schema_file_id: :rand.uniform(10000),
        ir_schema: %{
          "types" => %{
            "TestType" => %{
              "struct" => %{
                "name" => "TestType",
                "fields" => fields
              }
            }
          }
        },
        squishability_score: score,
        transport_classes: classes,
        field_count: field_count,
        type_diversity: 1
      }
    end
  end

  defp field_gen do
    gen all(
          name <- member_of(["id", "name", "email", "created_at", "status", "count", "data"]),
          type <- member_of(["String", "I32", "I64", "Bool", "F64"]),
          optional <- boolean()
        ) do
      %{
        "name" => name,
        "ty" => %{"Primitive" => type},
        "optional" => optional
      }
    end
  end

  property "detect_all returns list of tuples with valid structure" do
    check all(results <- list_of(analysis_result_gen(), min_length: 1, max_length: 20)) do
      patterns = PatternDetector.detect_all(results)

      assert is_list(patterns)

      for {type, data} <- patterns do
        assert is_atom(type)
        assert is_map(data)
        assert is_integer(data.frequency)
        assert data.frequency > 0
        assert is_float(data.confidence)
        assert data.confidence >= 0.0
        assert data.confidence <= 1.0
        assert is_binary(data.description)
      end
    end
  end

  property "detect_format_prevalence frequency equals total results" do
    check all(results <- list_of(analysis_result_gen(), min_length: 1, max_length: 50)) do
      result = PatternDetector.detect_format_prevalence(results)
      assert result.frequency == length(results)
    end
  end

  property "detect_field_name_patterns never returns negative frequency" do
    check all(results <- list_of(analysis_result_gen(), min_length: 0, max_length: 20)) do
      result = PatternDetector.detect_field_name_patterns(results)
      assert result.frequency >= 0
    end
  end
end
