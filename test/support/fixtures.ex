# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Fixtures do
  @moduledoc """
  Test fixtures for schema files and analysis results.
  """

  alias SquisherCorpus.Repo
  alias SquisherCorpus.Schemas.{GithubRepo, SchemaFile, AnalysisResult}

  def github_repo_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        owner: "testowner",
        name: "testrepo-#{System.unique_integer([:positive])}",
        stars: 42,
        language: "Rust"
      })

    %GithubRepo{}
    |> GithubRepo.changeset(attrs)
    |> Repo.insert!()
  end

  def schema_file_fixture(attrs \\ %{}) do
    github_repo = attrs[:github_repo] || github_repo_fixture()

    attrs =
      attrs
      |> Map.delete(:github_repo)
      |> Enum.into(%{
        github_repo_id: github_repo.id,
        path: "schemas/test.proto",
        format: "protobuf",
        sha: "sha_#{System.unique_integer([:positive])}",
        raw_content: ~s(syntax = "proto3";\nmessage Test { string name = 1; int32 id = 2; }),
        size_bytes: 64
      })

    %SchemaFile{}
    |> SchemaFile.changeset(attrs)
    |> Repo.insert!()
  end

  def analysis_result_fixture(attrs \\ %{}) do
    schema_file = attrs[:schema_file] || schema_file_fixture()

    attrs =
      attrs
      |> Map.delete(:schema_file)
      |> Enum.into(%{
        schema_file_id: schema_file.id,
        ir_schema: %{
          "name" => "Test",
          "types" => %{
            "Test" => %{
              "struct" => %{
                "name" => "Test",
                "fields" => [
                  %{"name" => "name", "ty" => %{"Primitive" => "String"}, "optional" => false},
                  %{"name" => "id", "ty" => %{"Primitive" => "I32"}, "optional" => false}
                ]
              }
            }
          }
        },
        squishability_score: 0.75,
        transport_classes: ["Concorde", "Business"],
        field_count: 2,
        type_diversity: 1
      })

    %AnalysisResult{}
    |> AnalysisResult.changeset(attrs)
    |> Repo.insert!()
  end

  def protobuf_content do
    """
    syntax = "proto3";

    package example;

    message UserProfile {
      string name = 1;
      int32 age = 2;
      string email = 3;
      repeated string tags = 4;
      optional string bio = 5;
    }

    message Address {
      string street = 1;
      string city = 2;
      string country = 3;
      int32 zip = 4;
    }
    """
  end

  def avro_content do
    Jason.encode!(%{
      "type" => "record",
      "name" => "User",
      "namespace" => "com.example",
      "fields" => [
        %{"name" => "name", "type" => "string"},
        %{"name" => "age", "type" => "int"},
        %{"name" => "email", "type" => ["null", "string"]}
      ]
    })
  end
end
