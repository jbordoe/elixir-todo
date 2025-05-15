defmodule Todo.Database.Worker do
  @moduledoc """
  The database worker process for the todo application.
  """
  use GenServer

  def start_link(db_folder, worker_id) do
    IO.puts("Starting to-do database worker #{worker_id}")
    GenServer.start_link(__MODULE__, db_folder, name: via_tuple(worker_id))
  end

  def store(worker_id, key, value) do
    GenServer.cast(via_tuple(worker_id), {:store, key, value})
  end

  def get(worker_id, key) do
    GenServer.call(via_tuple(worker_id), {:get, key})
  end

  def init(db_folder) do
    File.mkdir_p(db_folder)
    {:ok, db_folder}
  end

  def handle_cast({:store, key, value}, db_folder) do
    Path.join(db_folder, key)
    |> File.write!(:erlang.term_to_binary(value))

    {:noreply, db_folder}
  end

  def handle_call({:get, key}, _caller, db_folder) do
    data = case File.read(Path.join(db_folder, key)) do
      {:ok, binary} -> :erlang.binary_to_term(binary)
      _ -> nil
    end

    {:reply, data, db_folder}
  end

  defp via_tuple(worker_id) do
    {:via, Todo.ProcessRegistry, {:database_worker, worker_id}}
  end
end
