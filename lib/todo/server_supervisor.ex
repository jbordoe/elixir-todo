defmodule Todo.ServerSupervisor do
  @moduledoc """
  The supervisor process for the todo application.
  """
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_child(todo_list_name) do
    DynamicSupervisor.start_child(__MODULE__, child_spec(todo_list_name))
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp child_spec(todo_list_name) do
    %{
      id: Todo.Server,
      start: {Todo.Server, :start_link, [todo_list_name]},
      restart: :permanent,
      type: :worker
    }
  end
end
