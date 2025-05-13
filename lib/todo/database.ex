defmodule Todo.Database do
  @moduledoc """
  The database process for the todo application.
  """
  use GenServer

  @process_name :todo_database
  @worker_pool_size 3

  ## Interface Functions
  def start(db_folder) do
    GenServer.start(
      __MODULE__,
      db_folder,
      name: @process_name
    )
  end

  def store(key, value) do
    GenServer.cast(@process_name, {:store, key, value})
  end

  def get(key) do
    GenServer.call(@process_name, {:get, key})
  end

  def init(db_folder) do
    File.mkdir_p(db_folder)
    worker_pids = 1..@worker_pool_size
      |> Enum.map(fn _ ->
        {:ok, pid} = Todo.Database.Worker.start(db_folder)
        pid
      end)
    {:ok, worker_pids}
  end

  def handle_cast({:store, key, value}, worker_pids) do
    get_worker_pid(key, worker_pids)
    |> Todo.Database.Worker.store(key, value)
    {:noreply, worker_pids}
  end

  def handle_call({:get, key}, _caller, worker_pids) do
    data = get_worker_pid(key, worker_pids)
    |> Todo.Database.Worker.get(key)

    {:reply, data, worker_pids}
  end

  defp get_worker_pid(key, worker_pids) do
    Enum.at(worker_pids, :erlang.phash2(key, @worker_pool_size))
  end
end
