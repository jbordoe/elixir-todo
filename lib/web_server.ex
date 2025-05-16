defmodule WebServer do
  @moduledoc """
  This module provides a simple HTTP server.
  """

  def index do
    :timer.sleep(1000)

    "<html><body>Hello World!</body></html>"
  end
end
