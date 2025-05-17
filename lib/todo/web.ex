defmodule Todo.Web do
  @moduledoc """
  The web server for the todo application.
  """
  use Plug.Router

  require Jason

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Hello, world!")
  end

  # TODO: fetch entry by ID
  get "/entries/:list/date/:date" do
    conn
    |> Plug.Conn.fetch_query_params()
    |> entries()
    |> respond()
  end

  delete "/entries/:list/:entry_id" do
    conn
    |> Plug.Conn.fetch_query_params()
    |> delete_entry()
    |> respond()
  end

  post "/add_entry" do
    conn
    |> Plug.Conn.fetch_query_params()
    |> add_entry()
    |> respond()
  end

  def start_server do
    IO.puts("Starting the web server...")
    Plug.Cowboy.http(__MODULE__, [], port: 4000)
  end

  defp entries(conn) do
    entries = conn.params["list"]
      |> Todo.Cache.server_process()
      |> Todo.Server.entries(conn.params["date"])
    Plug.Conn.assign(conn, :response, %{status: "success", entries: entries})
  end

  defp add_entry(conn) do
    conn.params["list"]
      |> Todo.Cache.server_process()
      |> Todo.Server.add_entry(%{
      date: conn.params["date"],
      title: conn.params["title"],
    })
    Plug.Conn.assign(conn, :response, %{status: "success", message: "added"})
  end

  defp delete_entry(conn) do
    conn.params["list"]
      |> Todo.Cache.server_process()
      |> Todo.Server.delete_entry(String.to_integer(conn.params["entry_id"]))
    Plug.Conn.assign(conn, :response, %{status: "success", message: "deleted"})
  end

  defp respond(conn) do
    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json")
    |> Plug.Conn.send_resp(200, Jason.encode!(conn.assigns[:response]))
  end
end
