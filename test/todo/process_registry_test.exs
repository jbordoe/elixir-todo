defmodule Todo.ProcessRegistryTest do
  use ExUnit.Case, async: true
  alias Todo.ProcessRegistry

  setup do
    # Start a fresh ProcessRegistry for each test
    {:ok, registry} = ProcessRegistry.start_link()

    on_exit(fn ->
      Process.exit(registry, :normal)
    end)
    # Return the registry pid for test cases
    %{registry: registry}
  end

  describe "registration" do
    test "can register a process" do
      assert :yes == ProcessRegistry.register_name(:test_process, self())
      assert self() == ProcessRegistry.whereis_name(:test_process)
    end

    test "cannot register the same key twice" do
      # First registration succeeds
      assert :yes == ProcessRegistry.register_name(:test_process, self())
      
      # Create another process
      other_pid = spawn(fn -> receive do :stop -> :ok end end)
      
      # Second registration with same key fails
      assert :no == ProcessRegistry.register_name(:test_process, other_pid)
      
      # Original process remains registered
      assert self() == ProcessRegistry.whereis_name(:test_process)
      
      # Clean up
      send(other_pid, :stop)
    end

    test "can register different keys for the same process" do
      assert :yes == ProcessRegistry.register_name(:test_key1, self())
      assert :yes == ProcessRegistry.register_name(:test_key2, self())
      
      assert self() == ProcessRegistry.whereis_name(:test_key1)
      assert self() == ProcessRegistry.whereis_name(:test_key2)
    end
  end

  describe "unregistration" do
    test "can unregister a process" do
      # Register
      ProcessRegistry.register_name(:test_process, self())
      assert self() == ProcessRegistry.whereis_name(:test_process)
      
      # Unregister
      ProcessRegistry.unregister_name(:test_process)
      # Sleep to allow the process to unregister
      :timer.sleep(100)
      assert :undefined == ProcessRegistry.whereis_name(:test_process)
    end

    test "unregistering a non-existent key is a no-op" do
      # This should not raise any error
      ProcessRegistry.unregister_name(:non_existent)
      assert :undefined == ProcessRegistry.whereis_name(:non_existent)
    end
  end

  describe "process monitoring" do
    test "automatically unregisters a process when it terminates" do
      # Create a process to register
      test_pid = self()
      
      # Start a monitored process that will register itself
      pid = spawn(fn -> 
        ProcessRegistry.register_name(:monitored_process, self())
        send(test_pid, :registered)
        receive do :stop -> :ok end
      end)
      
      # Wait for registration
      receive do :registered -> :ok end
      
      # Verify it's registered
      assert pid == ProcessRegistry.whereis_name(:monitored_process)
      
      # Terminate the process
      send(pid, :stop)
      
      # Give the registry time to receive and process the DOWN message
      Process.sleep(100)
      
      # Verify the process was automatically unregistered
      assert :undefined == ProcessRegistry.whereis_name(:monitored_process)
    end
  end

  describe "send functionality" do
    test "can send a message to a registered process" do
      # Register this test process
      ProcessRegistry.register_name(:message_receiver, self())
      
      # Send a message using the registry
      ProcessRegistry.send(:message_receiver, :test_message)
      
      # Check that we received the message
      assert_receive :test_message
    end

    test "returns error when sending to an unregistered name" do
      result = ProcessRegistry.send(:unregistered_name, :test_message)
      assert {:badarg, {:unregistered_name, :test_message}} = result
      
      # Make sure we didn't receive the message
      refute_receive :test_message
    end
  end

  describe "concurrent operations" do
    test "handles concurrent registrations correctly" do
      # Create multiple processes that will try to register with the same key
      test_pid = self()
      
      # Number of concurrent processes to create
      process_count = 100
      
      # Spawn processes that will all try to register with the same key
      for _ <- 1..process_count do
        spawn(fn ->
          result = ProcessRegistry.register_name(:concurrent_test, self())
          send(test_pid, {:registration_result, self(), result})
          receive do :stop -> :ok end
        end)
      end
      
      # Collect results
      results = for _ <- 1..process_count do
        receive do
          {:registration_result, pid, result} -> {pid, result}
        end
      end
      
      # Only one should have succeeded
      successful_registrations = Enum.filter(results, fn {_pid, result} -> result == :yes end)
      assert length(successful_registrations) == 1
      
      # The rest should have failed
      failed_registrations = Enum.filter(results, fn {_pid, result} -> result == :no end)
      assert length(failed_registrations) == process_count - 1
      
      # The process that succeeded should be the one registered
      [{successful_pid, :yes}] = successful_registrations
      assert successful_pid == ProcessRegistry.whereis_name(:concurrent_test)
      
      # Clean up - stop all spawned processes
      for {pid, _} <- results do
        send(pid, :stop)
      end
    end
  end

  describe "debug functionality" do
    test "debug returns the internal registry state" do
      # Register a process
      ProcessRegistry.register_name(:debug_test, self())
      
      # Get debug output
      registry_state = ProcessRegistry.debug()
      
      # Verify the registry state contains our registration
      assert Map.get(registry_state, :debug_test) == self()
    end
  end
end
