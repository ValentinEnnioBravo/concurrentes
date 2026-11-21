defmodule Vuelos.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies, [])

    children = [
      # libcluster corre como un proceso más del árbol de supervisión
      {Cluster.Supervisor, [topologies, [name: Vuelos.ClusterSupervisor]]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Vuelos.Supervisor)
  end
end
