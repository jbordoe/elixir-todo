defmodule Todo.SystemSupervisor do
  @moduledoc """
  The supervisor process for the todo application.
  """
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    children = [
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
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
