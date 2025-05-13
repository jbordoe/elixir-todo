defmodule Todo.Server do
  @moduledoc """
  The server process for the todo application.
  """
  use GenServer

  ## Interface Functions
  def start do
    GenServer.start(Todo.Server, [])
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

  ## Callbacks
  def init(_), do: {:ok, Todo.List.new()}

  def handle_cast({:add_entry, new_entry}, todo_list) do
    new_state = Todo.List.add_entry(todo_list, new_entry)
    {:noreply, new_state}
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    new_state = Todo.List.delete_entry(todo_list, entry_id)
    {:noreply, new_state}
  end

  def handle_cast({:update_entry, entry_id, updater_fun}, todo_list) do
    new_state = Todo.List.update_entry(todo_list, entry_id, updater_fun)
    {:noreply, new_state}
  end

  def handle_call({:entries, date}, _caller, todo_list) do
    entries = Todo.List.entries(todo_list, date)
    {:reply, entries, todo_list}
  end

  # TODO: log unsupported messages
  def handle_info(_, state), do: {:noreply, state}
end
