defmodule ObserverUi.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    unless Node.alive?() do
      Logger.error("""
      El observador tiene que correr como nodo distribuido y oculto, con la misma cookie que el cluster:

          iex --sname observer --cookie secreto --hidden -S mix
      """)
    end

    port = Application.fetch_env!(:observer_ui, :port)

    children = [
      # "PubSub" mínimo: los clientes SSE se registran acá para recibir los snapshots
      {Registry, keys: :duplicate, name: ObserverUi.PubSub},
      ObserverUi.ClusterWatcher,
      ObserverUi.Launcher,
      {Bandit, plug: ObserverUi.Router, port: port}
    ]

    Logger.info("UI del observador en http://localhost:#{port}")
    Supervisor.start_link(children, strategy: :one_for_one, name: ObserverUi.Supervisor)
  end
end
