defmodule Todo.Cache do
  @moduledoc """
  The cache process for the todo application.
  """
  use GenServer

  @process_name :todo_cache

  ## Interface Functions
  def start_link do
    IO.puts("Starting the to-do cache process...")
    GenServer.start_link(__MODULE__, nil, name: @process_name)
  end

  def server_process(todo_list_name) do
    # Prevent race conditions by checking if the server process exists
    unless Todo.Server.whereis(todo_list_name) do
      GenServer.call(@process_name, {:server_process, todo_list_name})
    end
  end

  def init(_) do
    Todo.Database.start_link("./persist")
    {:ok, Map.new()}
  end

  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    # check if the server process exists
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        {:reply, todo_server, todo_servers}
      :error ->
        {:ok, todo_server} = Todo.Server.start_link(todo_list_name)
        todo_servers = Map.put(todo_servers, todo_list_name, todo_server)
        {:reply, todo_server, todo_servers}
    end
  end
end
