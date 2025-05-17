defmodule Todo.Server do
  @moduledoc """
  The server process for the todo application.
  """
  use GenServer

  ## Interface Functions
  def start_link(todo_list_name) do
    IO.puts("Starting todo server for #{todo_list_name}")
    GenServer.start_link(
      Todo.Server,
      [todo_list_name],
      name: {:global, {__MODULE__, todo_list_name}}
    )
  end

  def add_entry(server_pid, new_entry) do
    GenServer.cast(server_pid, {:add_entry, new_entry})
  end

  def delete_entry(server_pid, entry_id) do
    GenServer.cast(server_pid, {:delete_entry, entry_id})
  end

  def update_entry(server_pid, entry_id, updater_fun) do
    GenServer.cast(server_pid, {:update_entry, entry_id, updater_fun})
  end

  def entries(server_pid, date) do
    GenServer.call(server_pid, {:entries, date})
  end

  def whereis(todo_list_name) do
    :global.whereis_name({__MODULE__, todo_list_name})
  end

  ## Callbacks
  def init(todo_list_name) do
    send(self(), {:real_init, todo_list_name})
    {:ok, nil}
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    new_state = Todo.List.add_entry(todo_list, new_entry)
    persist(new_state)
    {:noreply, new_state}
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    new_state = Todo.List.delete_entry(todo_list, entry_id)
    persist(new_state)
    {:noreply, new_state}
  end

  def handle_cast({:update_entry, entry_id, updater_fun}, todo_list) do
    new_state = Todo.List.update_entry(todo_list, entry_id, updater_fun)
    persist(new_state)
    {:noreply, new_state}
  end

  def handle_call({:entries, date}, _caller, todo_list) do
    entries = Todo.List.entries(todo_list, date)
    {:reply, entries, todo_list}
  end

  def handle_info({:real_init, todo_list_name}, _state) do
    todo_list = Todo.Database.get(todo_list_name) || %Todo.List{name: todo_list_name}
    {:noreply, todo_list}
  end

  defp persist(todo_list) do
    Todo.Database.store(todo_list.name, todo_list)
  end
end
