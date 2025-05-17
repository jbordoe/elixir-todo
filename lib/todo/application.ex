defmodule Todo.Application do
  @moduledoc """
  The main application module for the todo application.
  """
  use Application

  def start(_type, _args) do
    IO.puts("Starting the to-do application...")
    response = Todo.Supervisor.start_link()
    Todo.Web.start_server()
    response
  end
end
