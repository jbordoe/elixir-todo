defmodule Todo.Database.Worker do
  @moduledoc """
  The database worker process for the todo application.
  """
  use GenServer

  def start_link(db_folder) do
    IO.puts("Starting to-do database worker...")
    GenServer.start_link(__MODULE__, db_folder)
  end

  def store(pid, key, value) do
    GenServer.cast(pid, {:store, key, value})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
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
end
