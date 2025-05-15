defmodule Todo.Database.PoolSupervisor do
  @moduledoc """
  The pool supervisor for the todo database worker processes.
  """
  use Supervisor

  def start_link(db_folder, pool_size) do
    IO.puts("Starting the to-do database pool supervisor...")
    Supervisor.start_link(__MODULE__, {db_folder, pool_size}, name: __MODULE__)
  end

  def init({db_folder, pool_size}) do
    children = 1..pool_size
      |> Enum.map(fn n ->
        %{
          id: {:database_worker, n},
          start: {Todo.Database.Worker, :start_link, [db_folder, n]},
          type: :worker
        }
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
