defmodule Todo.ProcessRegistry do
  @moduledoc """
  The process registry for the todo application.
  """
  use GenServer
  import Kernel, except: [send: 2]

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
    GenServer.call(__MODULE__, {:whereis_name, key})
  end

  def init(_) do
    {:ok, Map.new()}
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

  def handle_call({:register_name, key, process_pid}, _caller, process_registry) do
    case Map.get(process_registry, key) do
      nil ->
        Process.monitor(process_pid)
        {:reply, :yes, Map.put(process_registry, key, process_pid)}
      _ ->
        {:reply, :no, process_registry}
        # TODO: log duplicate registration
    end 
  end

  def handle_call({:whereis_name, key}, _caller, process_registry) do
    {
      :reply,
      Map.get(process_registry, key, :undefined),
      process_registry
    }
  end

  def handle_cast({:unregister_name, key}, process_registry) do
    {:noreply, deregister_pid(process_registry, key)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, process_registry) do
    {:noreply, deregister_pid(process_registry, pid)}
    # TODO: log process down
  end
  
  defp deregister_pid(process_registry, key) do
    Map.delete(process_registry, key)
  end
end
