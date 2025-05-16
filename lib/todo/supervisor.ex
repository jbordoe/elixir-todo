defmodule Todo.Supervisor do
  @moduledoc """
  The supervisor process for the todo application.
  """
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    children = [
      %{
        id: Todo.ProcessRegistry,
        start: {Todo.ProcessRegistry, :start_link, []},
        restart: :permanent,
        type: :worker
      },
      %{
        id: Todo.Database.PoolSupervisor,
        start: {Todo.Database.PoolSupervisor, :start_link, ["./persist", 3]},
        restart: :permanent,
        type: :supervisor
      },
      %{
        id: Todo.ServerSupervisor,
        start: {Todo.ServerSupervisor, :start_link, []},
        restart: :permanent,
        type: :supervisor
      },
      %{
        id: Todo.Cache,
        start: {Todo.Cache, :start_link, []},
        restart: :permanent,
        type: :worker
      }
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
