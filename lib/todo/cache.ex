defmodule Todo.Cache do
  @moduledoc """
  The cache process for the todo application.
  """
  use GenServer

  @process_name :todo_cache

  ## Interface Functions
  def start do
    GenServer.start(
      __MODULE__,
      [],
      name: @process_name
    )
  end

  def server_process(todo_list_name) do
    GenServer.call(@process_name, {:server_process, todo_list_name})
  end

  def init(_) do
    Todo.Database.start("./persist")
    {:ok, Map.new()}
  end

  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}
      :error ->
        {:ok, todo_server} = Todo.Server.start(todo_list_name)
        todo_servers = Map.put(todo_servers, todo_list_name, todo_server)
        {:reply, todo_server, todo_servers}
    end
  end
end
