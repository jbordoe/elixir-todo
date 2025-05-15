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
        id: Todo.Cache,
        start: {Todo.Cache, :start_link, []},
        restart: :permanent,
        type: :worker
      }
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
