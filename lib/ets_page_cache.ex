defmodule EtsPageCache do
  @moduledoc """
  This module provides a simple page cache using ETS.
  """
  use GenServer

  @ets_table :page_cache

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def cached(key, func) do
    read_cached(key) || GenServer.call(__MODULE__, {:cache, key, func})
  end

  def init(_) do
    :ets.new(@ets_table, [:set, :protected, :named_table])
    {:ok, nil}
  end

  def handle_call({:cache, key, func}, _from, state) do
    {
      :reply,
      read_cached(key) || cache_result(key, func),
      state
    }
  end

  defp read_cached(key) do
    case :ets.lookup(@ets_table, key) do
      [{^key, value}] -> value
      _ -> nil
    end
  end

  defp cache_result(key, func) do
    value = func.()
    :ets.insert(@ets_table, {key, value})
    value
  end
end
