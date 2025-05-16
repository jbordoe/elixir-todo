defmodule Todo.Database do
  @moduledoc """
  The database process for the todo application.
  """
  @pool_size 3

  def store(key, value) do
    key
    |> choose_worker()
    |> Todo.Database.Worker.store(key, value)
  end

  def get(key) do
    key
    |> choose_worker()
    |> Todo.Database.Worker.get(key)
  end

  defp choose_worker(key) do
    :erlang.phash2(key, @pool_size) + 1
  end
end
