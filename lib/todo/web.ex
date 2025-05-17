defmodule Todo.Web do
  @moduledoc """
  The web server for the todo application.
  """
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Hello, world!")
  end

  def start_server do
    IO.puts("Starting the web server...")
    Plug.Cowboy.http(__MODULE__, [], port: 4000)
  end
end
