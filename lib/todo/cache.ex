defmodule Todo.Cache do
  @moduledoc """
  The cache process for the todo application.
  Maps todo list names to server process PIDs.
  """
  def server_process(todo_list_name) do
    # Prevent race conditions by checking if the server process exists
    case Todo.Server.whereis(todo_list_name) do
      :undefined -> create_server(todo_list_name)
      pid -> pid
    end
  end

  defp create_server(todo_list_name) do
    case Todo.ServerSupervisor.start_child(todo_list_name) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end
end
