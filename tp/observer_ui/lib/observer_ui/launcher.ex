defmodule ObserverUi.Launcher do
  @moduledoc """
  Hace de "infraestructura": levanta y baja nodos del TP desde afuera, como lo
  haría systemd o Kubernetes.

  - **Levantar:** lanza un proceso del sistema operativo
    `elixir --sname nodoN --cookie <cookie> -S mix run --no-halt` dentro de la
    carpeta del TP. La salida de cada nodo va a `logs/nodoN.log`.
  - **Bajar:** `:init.stop/0` en el nodo remoto, el apagado ordenado de OTP.

  El TP no tiene código para nada de esto.
  """
  use GenServer
  require Logger

  alias ObserverUi.ClusterWatcher

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Levanta un nodo nuevo con el primer nombre libre. Devuelve `{:ok, node}`."
  def start_node, do: GenServer.call(__MODULE__, :start_node, 10_000)

  @doc "Da de baja un nodo del TP por su nombre completo (`\"nodo1@host\"`)."
  def stop_node(name) when is_binary(name) do
    node = String.to_existing_atom(name)

    if ClusterWatcher.target_node?(node) do
      ClusterWatcher.mark(node, :stopping)
      ClusterWatcher.log(:info, "Bajando #{name}")
      :erpc.cast(node, :init, :stop, [])
      :ok
    else
      {:error, :not_found}
    end
  rescue
    ArgumentError -> {:error, :not_found}
  end

  ## Callbacks

  @impl true
  def init(_opts) do
    Process.flag(:trap_exit, true)
    logs_dir = Path.expand("logs", File.cwd!())
    File.mkdir_p!(logs_dir)

    {:ok,
     %{
       target_path: Application.fetch_env!(:observer_ui, :target_path),
       prefix: Application.fetch_env!(:observer_ui, :node_prefix),
       logs_dir: logs_dir,
       # port => %{node, short, log}
       ports: %{}
     }}
  end

  @impl true
  def handle_call(:start_node, _from, state) do
    short = next_free_name(state)
    node = :"#{short}@#{ClusterWatcher.local_host()}"
    cookie = Node.get_cookie() |> Atom.to_string()
    {exe, args} = command(short, cookie)

    try do
      port =
        Port.open({:spawn_executable, exe}, [
          :binary,
          :exit_status,
          :stderr_to_stdout,
          args: args,
          cd: state.target_path
        ])

      log = File.open!(Path.join(state.logs_dir, "#{short}.log"), [:write, :utf8])
      ClusterWatcher.mark(node, :starting)
      ClusterWatcher.log(:info, "Levantando #{short} (logs/#{short}.log)")

      {:reply, {:ok, node}, put_in(state.ports[port], %{node: node, short: short, log: log})}
    rescue
      e ->
        msg = "No se pudo lanzar #{short}: #{Exception.message(e)}"
        Logger.error(msg)
        ClusterWatcher.log(:error, msg)
        {:reply, {:error, msg}, state}
    end
  end

  @impl true
  def handle_info({port, {:data, data}}, state) do
    case state.ports[port] do
      %{log: log} -> IO.binwrite(log, data)
      nil -> :ok
    end

    {:noreply, state}
  end

  def handle_info({port, {:exit_status, status}}, state) do
    case Map.pop(state.ports, port) do
      {%{node: node, short: short, log: log}, ports} ->
        File.close(log)
        ClusterWatcher.unmark(node)

        if status != 0 do
          ClusterWatcher.log(:error, "#{short} terminó con código #{status} (ver logs/#{short}.log)")
        end

        {:noreply, %{state | ports: ports}}

      {nil, _} ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, _port, _reason}, state), do: {:noreply, state}

  ## Helpers

  defp next_free_name(state) do
    used =
      case :erl_epmd.names() do
        {:ok, names} -> Enum.map(names, fn {name, _} -> to_string(name) end)
        _ -> []
      end ++ Enum.map(Map.values(state.ports), & &1.short)

    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(&"#{state.prefix}#{&1}")
    |> Enum.find(&(&1 not in used))
  end

  defp command(short, cookie) do
    elixir_args = ["--sname", short, "--cookie", cookie, "-S", "mix", "run", "--no-halt"]

    case :os.type() do
      # En Windows `elixir` es un .bat, así que se lanza a través de cmd.exe
      {:win32, _} ->
        cmd = System.get_env("ComSpec") || System.find_executable("cmd") || "cmd.exe"
        {cmd, ["/c", "elixir" | elixir_args]}

      _ ->
        {System.find_executable("elixir") || raise("no se encontró `elixir` en el PATH"),
         elixir_args}
    end
  end
end
