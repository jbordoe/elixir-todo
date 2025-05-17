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
        id: Todo.SystemSupervisor,
        start: {Todo.SystemSupervisor, :start_link, []},
        restart: :permanent,
        type: :supervisor
      }
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
