defmodule Todo.Server do
  @process_name :todo_server

  def start do
    pid = spawn(fn -> loop(Todo.List.new) end)
    Process.register(pid, @process_name)
  end

  def add_entry(new_entry) do
    send(@process_name, {:add_entry, new_entry})
  end

  def delete_entry(entry_id) do
    send(@process_name, {:delete_entry, entry_id})
  end
  
  def update_entry(entry_id, updater_fun) do
    send(@process_name, {:update_entry, entry_id, updater_fun})
  end
  
  def entries(date) do
    send(@process_name, {:entries, self(), date})
    receive do
      {:todo_entries, entries} -> entries
    after 5000 ->
      {:error, :timeout}
    end
  end

  defp process_message(todo_list, {:add_entry, new_entry}) do
    Todo.List.add_entry(todo_list, new_entry)
  end

  defp process_message(todo_list, {:delete_entry, entry_id}) do
    Todo.List.delete_entry(todo_list, entry_id)
  end

  defp process_message(todo_list, {:update_entry, entry_id, updater_fun}) do
    Todo.List.update_entry(todo_list, entry_id, updater_fun)
  end

  defp process_message(todo_list, {:entries, caller, date}) do
    entries = Todo.List.entries(todo_list, date)
    send(caller, {:todo_entries, entries})
    todo_list
  end

  # TODO: log unsupported messages

  defp loop(todo_list) do
    new_todo_list = receive do
      message ->
        process_message(todo_list, message)
    end

    loop(new_todo_list)
  end
end 
