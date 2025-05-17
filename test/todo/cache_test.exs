defmodule Todo.CacheTest do
  use ExUnit.Case, async: false
  
  # Using async: false since we're testing a singleton process
  
  describe "server_process/1" do
    test "returns a pid for a given list name" do
      pid = Todo.Cache.server_process("test_list")
      assert is_pid(pid)
    end
    
    test "returns the same pid for the same list name" do
      pid1 = Todo.Cache.server_process("test_list_same")
      pid2 = Todo.Cache.server_process("test_list_same")
      assert pid1 == pid2
    end
    
    test "returns different pids for different list names" do
      pid1 = Todo.Cache.server_process("test_list_1")
      pid2 = Todo.Cache.server_process("test_list_2")
      assert pid1 != pid2
    end
    
    test "creates a new process if the existing one died" do
      # First get a server process
      pid1 = Todo.Cache.server_process("test_list_dead")
      
      # Kill the process
      Process.exit(pid1, :kill)
      
      # Allow some time for the process to die
      Process.sleep(10)
      
      # Try to get the process again - should be a new one
      pid2 = Todo.Cache.server_process("test_list_dead")
      assert Process.alive?(pid2)
      assert pid1 != pid2
    end
  end
  
  describe "cache behavior" do
    test "race conditions are handled properly" do
      # Simulate concurrent calls by making parallel requests
      tasks = for _ <- 1..20 do
        Task.async(fn -> Todo.Cache.server_process("concurrent_list") end)
      end
      
      # Get all results
      results = Task.await_many(tasks)
      
      # All calls should return the same PID
      [first_pid | rest] = results
      assert Enum.all?(rest, fn pid -> pid == first_pid end)
    end
  end
  
  describe "resilience" do
    test "cache survives if a server process crashes" do
      # Get a server process
      pid = Todo.Cache.server_process("crash_test")
      
      # Kill it
      Process.exit(pid, :kill)
      Process.sleep(10)
      
      # We should be able to get a new server
      new_pid = Todo.Cache.server_process("crash_test")
      assert Process.alive?(new_pid)
      assert pid != new_pid
    end
  end
  
  # Placeholder for distributed tests - to be expanded after :global integration
  @tag :distributed
  describe "distributed behavior" do
    test "works in a distributed environment" do
      # After implementing :global support, expand this test
      # to verify processes are accessible across nodes
      :ok
    end
  end
end
