defmodule ObserverUi.Router do
  @moduledoc """
  HTTP de la UI.

  - `GET  /`                 página
  - `GET  /events`           Server-Sent Events: un snapshot del cluster cada vez que cambia
  - `GET  /api/cluster`      snapshot actual (JSON)
  - `POST /api/nodes`        levanta un nodo nuevo
  - `DELETE /api/nodes/:name` da de baja un nodo
  """
  use Plug.Router

  alias ObserverUi.{ClusterWatcher, Launcher}

  @keepalive_ms 15_000

  plug :match
  plug :dispatch

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, Application.app_dir(:observer_ui, "priv/static/index.html"))
  end

  get "/api/cluster" do
    json(conn, 200, ClusterWatcher.snapshot())
  end

  post "/api/nodes" do
    case Launcher.start_node() do
      {:ok, node} -> json(conn, 202, %{node: node})
      {:error, msg} -> json(conn, 500, %{error: msg})
    end
  end

  delete "/api/nodes/:name" do
    case Launcher.stop_node(name) do
      :ok -> json(conn, 202, %{node: name})
      {:error, :not_found} -> json(conn, 404, %{error: "#{name} no es un nodo del cluster"})
    end
  end

  get "/events" do
    {:ok, _} = ClusterWatcher.subscribe()

    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> send_chunked(200)

    case chunk(conn, sse(ClusterWatcher.snapshot())) do
      {:ok, conn} -> sse_loop(conn)
      {:error, _} -> conn
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  # El proceso de la conexión se queda esperando snapshots y los reenvía al navegador.
  defp sse_loop(conn) do
    receive do
      {:cluster_snapshot, snapshot} ->
        case chunk(conn, sse(snapshot)) do
          {:ok, conn} -> sse_loop(conn)
          {:error, _closed} -> conn
        end
    after
      @keepalive_ms ->
        case chunk(conn, ": keepalive\n\n") do
          {:ok, conn} -> sse_loop(conn)
          {:error, _closed} -> conn
        end
    end
  end

  defp sse(snapshot), do: "data: #{Jason.encode!(snapshot)}\n\n"

  defp json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
