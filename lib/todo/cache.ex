defmodule Todo.Cache do
  @moduledoc """
  The cache process for the todo application.
  Maps todo list names to server process PIDs.
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
    case Todo.Server.whereis(todo_list_name) do
      :undefined ->
        GenServer.call(@process_name, {:server_process, todo_list_name})
      pid ->
        pid
    end
  end

  def init(_) do
    {:ok, Map.new()}
  end

  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    # check if the server process exists
    case Map.fetch(todo_servers, todo_list_name) do
      {:ok, todo_server} ->
        if Process.alive?(todo_server) do
          {:reply, todo_server, todo_servers}
        else
          new_process_response(todo_list_name, todo_servers)
        end
      :error ->
        new_process_response(todo_list_name, todo_servers)
    end
  end

  defp new_process_response(todo_list_name, todo_servers) do
    {new_server_pid, todo_servers} = create_process(todo_list_name, todo_servers)
    {:reply, new_server_pid, todo_servers}
  end

  defp create_process(todo_list_name, todo_servers) do
    {:ok, new_server_pid} = Todo.ServerSupervisor.start_child(todo_list_name)
    todo_servers = Map.put(todo_servers, todo_list_name, new_server_pid)
    {new_server_pid, todo_servers}
  end
end
