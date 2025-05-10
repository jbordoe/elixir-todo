defmodule Todo.Server do
  @moduledoc """
  The server process for the todo application.
  """

  @process_name :todo_server

  ## Interface Functions
  def start do
    pid = ServerProcess.start(Todo.Server)
    Process.register(pid, @process_name)
  end

  def add_entry(new_entry) do
    ServerProcess.cast(@process_name, {:add_entry, new_entry})
  end

  def delete_entry(entry_id) do
    ServerProcess.cast(@process_name, {:delete_entry, entry_id})
  end

  def update_entry(entry_id, updater_fun) do
    ServerProcess.cast(@process_name, {:update_entry, entry_id, updater_fun})
  end

  def entries(date) do
    ServerProcess.call(@process_name, {:entries, self(), date})
  end

  ## Callbacks
  def init, do: Todo.List.new()

  def handle_cast({:add_entry, new_entry}, todo_list) do
    Todo.List.add_entry(todo_list, new_entry)
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    Todo.List.delete_entry(todo_list, entry_id)
  end

  def handle_cast({:update_entry, entry_id, updater_fun}, todo_list) do
    Todo.List.update_entry(todo_list, entry_id, updater_fun)
  end

  def handle_call({:entries, caller, date}, todo_list) do
    entries = Todo.List.entries(todo_list, date)
    {entries, todo_list}
  end

  # TODO: log unsupported messages
end
