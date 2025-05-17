defmodule Todo.ProcessRegistry do
  @moduledoc """
  The process registry for the todo application.
  """
  use GenServer
  import Kernel, except: [send: 2]

  @ets_table_name :todo_process_registry

  def start_link do
    IO.puts("Starting the to-do process registry...")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def register_name(key, process_pid) do
    GenServer.call(__MODULE__, {:register_name, key, process_pid})
  end

  def unregister_name(key) do
    GenServer.cast(__MODULE__, {:unregister_name, key})
  end

  def whereis_name(key) do
    case :ets.lookup(@ets_table_name, key) do
      [{^key, pid}] -> pid
      _ -> :undefined
    end
  end

  def init(_) do
    :ets.new(@ets_table_name, [:set, :protected, :named_table])
    {:ok, nil}
  end

  def send(key, message) do
    case whereis_name(key) do
      :undefined ->
        {:badarg, {key, message}}
      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  def debug do
    :ets.tab2list(@ets_table_name) |> Map.new() |> IO.inspect()
  end

  def handle_call({:register_name, key, process_pid}, _caller, state) do
    case whereis_name(key) do
      :undefined ->
        Process.monitor(process_pid)
        add_to_registry(key, process_pid)
        {:reply, :yes, state}
      _ ->
        {:reply, :no, state}
        # TODO: log duplicate registration
    end 
  end

  def handle_cast({:unregister_name, key}, _state) do
    {:noreply, deregister_name(key)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, _state) do
    IO.puts("Process down: #{inspect(pid)}")
    {:noreply, deregister_pid(pid)}
  end

  defp add_to_registry(key, process_pid) do
    :ets.insert(@ets_table_name, {key, process_pid})
  end

  defp deregister_name(key) do
    :ets.delete(@ets_table_name, key)
  end

  defp deregister_pid(pid) do
    IO.puts("Deregistering process: #{inspect(pid)}")
    :ets.match_delete(@ets_table_name, {:_, pid})
  end
end
