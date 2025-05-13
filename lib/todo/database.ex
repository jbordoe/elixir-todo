defmodule Todo.Database do
  @moduledoc """
  The database process for the todo application.
  """
  use GenServer

  @process_name :todo_database

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
