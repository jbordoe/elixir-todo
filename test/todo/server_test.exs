defmodule Todo.ServerTest do
  use ExUnit.Case

  setup do
    # Start a fresh Todo.Server for each test
    Todo.Server.start()

    on_exit(fn ->
      # Stop the server
      pid = Process.whereis(:todo_server)
      Process.exit(pid, :kill)
    end)

    :ok
  end

  test "add and retrieve entries" do
    today = ~D[2025-05-13]
    tomorrow = ~D[2025-05-14]
    
    # Add entries with different dates
    Todo.Server.add_entry(%{date: today, title: "Write tests"})
    Todo.Server.add_entry(%{date: today, title: "Implement feature"})
    Todo.Server.add_entry(%{date: tomorrow, title: "Refactor code"})
    
    # Retrieve and verify entries for today
    today_entries = Todo.Server.entries(today)
    assert length(today_entries) == 2
    
    titles = Enum.map(today_entries, &(&1.title))
    assert "Write tests" in titles
    assert "Implement feature" in titles
    
    # Verify tomorrow entries
    tomorrow_entries = Todo.Server.entries(tomorrow)
    assert length(tomorrow_entries) == 1
    assert hd(tomorrow_entries).title == "Refactor code"
  end
  
  test "delete an entry" do
    # Add an entry
    Todo.Server.add_entry(%{date: ~D[2025-05-13], title: "Task to delete"})
    
    # Get the entry ID
    [entry] = Todo.Server.entries(~D[2025-05-13])
    entry_id = entry.id
    
    # Delete the entry
    Todo.Server.delete_entry(entry_id)
    
    # Verify it's gone
    assert Todo.Server.entries(~D[2025-05-13]) == []
  end
  
  test "update an entry" do
    # Add an entry
    Todo.Server.add_entry(%{date: ~D[2025-05-13], title: "Original title"})
    
    # Get the entry ID
    [entry] = Todo.Server.entries(~D[2025-05-13])
    entry_id = entry.id
    
    # Update the entry
    Todo.Server.update_entry(entry_id, fn entry -> %{entry | title: "Updated title"} end)
    
    # Verify it's updated
    [updated_entry] = Todo.Server.entries(~D[2025-05-13])
    assert updated_entry.title == "Updated title"
  end
  
  test "update multiple entries" do
    date = ~D[2025-05-13]
    
    # Add multiple entries
    Todo.Server.add_entry(%{date: date, title: "First task"})
    Todo.Server.add_entry(%{date: date, title: "Second task"})
    
    # Get the entries
    entries = Todo.Server.entries(date)
    assert length(entries) == 2
    
    # Find the first entry
    first_entry = Enum.find(entries, fn entry -> entry.title == "First task" end)
    
    # Update just the first entry
    Todo.Server.update_entry(first_entry.id, fn entry -> %{entry | title: "Updated first task"} end)
    
    # Verify the update
    updated_entries = Todo.Server.entries(date)
    titles = Enum.map(updated_entries, &(&1.title))
    
    assert "Updated first task" in titles
    assert "Second task" in titles
    assert length(updated_entries) == 2
  end
  
  test "server restart preserves no data" do
    # Add some entries
    Todo.Server.add_entry(%{date: ~D[2025-05-13], title: "Test entry"})
    
    # Verify the entry exists
    assert length(Todo.Server.entries(~D[2025-05-13])) == 1
    
    # Stop and restart the server
    pid = Process.whereis(:todo_server)
    Process.exit(pid, :kill)
    
    # Wait briefly to ensure the process is terminated
    :timer.sleep(10)
    
    # Restart the server
    Todo.Server.start()
    
    # Verify the entry doesn't exist anymore (no persistence)
    assert Todo.Server.entries(~D[2025-05-13]) == []
  end
  
  test "concurrent operations work correctly" do
    date = ~D[2025-05-13]
    
    # Spawn multiple processes to add entries concurrently
    for i <- 1..5 do
      spawn(fn -> 
        Todo.Server.add_entry(%{date: date, title: "Task #{i}"})
      end)
    end
    
    # Wait briefly for all operations to complete
    :timer.sleep(50)
    
    # Verify all entries were added
    entries = Todo.Server.entries(date)
    assert length(entries) == 5
    
    # Verify all expected titles are present
    titles = Enum.map(entries, &(&1.title))
    for i <- 1..5 do
      assert "Task #{i}" in titles
    end
  end
  
  test "server handles high load" do
    # Add a large number of entries
    for i <- 1..100 do
      day = rem(i, 10) + 1
      date = Date.new!(2025, 5, day)
      Todo.Server.add_entry(%{date: date, title: "Task #{i}"})
    end
    
    # Verify entries for each day
    for day <- 1..10 do
      date = Date.new!(2025, 5, day)
      entries = Todo.Server.entries(date)
      assert length(entries) == 10
    end
  end
end
