# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.RateLimiter do
  @moduledoc """
  GenServer implementing token bucket rate limiting for the GitHub API.

  Tracks remaining API calls via X-RateLimit-Remaining headers.
  Provides separate buckets for search (30/min) and core (5000/hr) endpoints.
  """

  use GenServer

  defstruct search_remaining: 30,
            search_reset_at: nil,
            core_remaining: 5000,
            core_reset_at: nil

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @doc """
  Request permission to make an API call. Blocks until a token is available.
  Returns :ok or {:error, :rate_limited}.
  """
  @spec acquire(atom()) :: :ok | {:error, :rate_limited}
  def acquire(bucket \\ :core) do
    GenServer.call(__MODULE__, {:acquire, bucket}, 60_000)
  end

  @doc """
  Update rate limit state from GitHub API response headers.
  """
  @spec update_from_headers(atom(), map()) :: :ok
  def update_from_headers(bucket, headers) do
    GenServer.cast(__MODULE__, {:update_headers, bucket, headers})
  end

  @doc """
  Get current rate limit state for inspection.
  """
  @spec get_state() :: map()
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  # Server callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:acquire, :search}, _from, state) do
    now = System.system_time(:second)

    cond do
      state.search_remaining > 0 ->
        {:reply, :ok, %{state | search_remaining: state.search_remaining - 1}}

      state.search_reset_at != nil and now >= state.search_reset_at ->
        {:reply, :ok, %{state | search_remaining: 29, search_reset_at: nil}}

      state.search_reset_at != nil ->
        wait_ms = max((state.search_reset_at - now) * 1000, 0)
        Process.sleep(min(wait_ms, 60_000))
        {:reply, :ok, %{state | search_remaining: 29, search_reset_at: nil}}

      true ->
        # No reset info, conservative wait
        Process.sleep(2_000)
        {:reply, :ok, %{state | search_remaining: state.search_remaining}}
    end
  end

  def handle_call({:acquire, :core}, _from, state) do
    now = System.system_time(:second)

    cond do
      state.core_remaining > 0 ->
        {:reply, :ok, %{state | core_remaining: state.core_remaining - 1}}

      state.core_reset_at != nil and now >= state.core_reset_at ->
        {:reply, :ok, %{state | core_remaining: 4999, core_reset_at: nil}}

      state.core_reset_at != nil ->
        wait_ms = max((state.core_reset_at - now) * 1000, 0)
        Process.sleep(min(wait_ms, 60_000))
        {:reply, :ok, %{state | core_remaining: 4999, core_reset_at: nil}}

      true ->
        Process.sleep(1_000)
        {:reply, :ok, state}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, Map.from_struct(state), state}
  end

  @impl true
  def handle_cast({:update_headers, bucket, headers}, state) do
    remaining = parse_header(headers, "x-ratelimit-remaining")
    reset_at = parse_header(headers, "x-ratelimit-reset")

    state =
      case bucket do
        :search ->
          %{state | search_remaining: remaining || state.search_remaining, search_reset_at: reset_at}

        :core ->
          %{state | core_remaining: remaining || state.core_remaining, core_reset_at: reset_at}
      end

    {:noreply, state}
  end

  defp parse_header(headers, name) do
    headers
    |> Enum.find(fn {k, _v} -> String.downcase(to_string(k)) == name end)
    |> case do
      {_, value} -> String.to_integer(to_string(value))
      nil -> nil
    end
  end
end
