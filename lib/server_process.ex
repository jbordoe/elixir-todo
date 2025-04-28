defmodule Todo.ServerProcess do
  @moduledoc """
  A generic server process.
  """
  def start(callback_module) do
    spawn(fn ->
      inital_state = callback_module.init
      loop(callback_module, inital_state)
    end)
  end

  def call(server_pid, request) do
    send(server_pid, {request, self})
    receive do
      {:response, response} -> response
    end
  end

  defp loop(callback_module, state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request, current_state)

        send(caller, {:response, response})
        loop(callback_module, new_state)

      {:cast, request, caller} ->
        {response, new_state} = callback_module.handle_cast(request, current_state)

        loop(callback_module, new_state)
    end
  end
end
