defmodule Todo.ServerSupervisor do
  @moduledoc """
  The supervisor process for the todo application.
  """
  use Supervisor

  @supervisor_alias :todo_server_supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: @supervisor_alias)
  end

  def start_child(todo_list_name) do
    Supervisor.start_child(@supervisor_alias, [todo_list_name])
  end

  def init(_) do
    children = [
      %{
        id: Todo.Server,
        start: {Todo.Server, :start_link, []},
        restart: :permanent,
        type: :worker
      }
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
