defmodule PageCache do
  @moduledoc """
  This module provides a simple page cache.
  """
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def cache(key, func) do
    GenServer.call(__MODULE__, {:cache, key, func})
  end

  def init(_) do
    {:ok, Map.new()}
  end

  def handle_call({:cache, key, func}, _from, state) do
    case Map.get(state, key) do
      nil ->
        value = func.()
        {:reply, value, Map.put(state, key, value)}

      value ->
        {:reply, value, state}
    end
  end
end
