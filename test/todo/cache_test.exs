defmodule Todo.CacheTest do
  use ExUnit.Case, async: false
  
  # Using async: false since we're testing a singleton process
  
  setup do
    # Stop the application if it's already running
    :application.stop(:todo)
    # Ensure the application won't auto-start by setting the flag
    :ok = :application.set_env(:todo, :start_immediately, false)
    Todo.ServerSupervisor.start_link()
    tmp_dir = Path.join(System.tmp_dir!(), "todo_test")
    {:ok, db_pid} = Todo.Database.PoolSupervisor.start_link(tmp_dir, 3)
    # Start a fresh cache for each test
    {:ok, cache_pid} = Todo.Cache.start_link()
    
    on_exit(fn ->
      if Process.alive?(cache_pid), do: Process.exit(cache_pid, :kill)
      Process.exit(db_pid, :kill)
    end)
    
    %{cache_pid: cache_pid}
  end
  
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
    
    test "creates a new process if the existing one died", %{cache_pid: cache_pid} do
      # First get a server process
      pid1 = Todo.Cache.server_process("test_list_dead")
      
      # Get the cache's internal state
      cache_state = :sys.get_state(cache_pid)
      assert Map.get(cache_state, "test_list_dead") == pid1
      
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
    test "cache maintains state across multiple calls", %{cache_pid: cache_pid} do
      # Get some server processes
      pid1 = Todo.Cache.server_process("test_state_1")
      pid2 = Todo.Cache.server_process("test_state_2")
      
      # Verify the cache has these processes in its state
      cache_state = :sys.get_state(cache_pid)
      assert Map.get(cache_state, "test_state_1") == pid1
      assert Map.get(cache_state, "test_state_2") == pid2
    end
    
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
      
      # Cache process should still be running
      assert Process.alive?(Process.whereis(:todo_cache))
      
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
