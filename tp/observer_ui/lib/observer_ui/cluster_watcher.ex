defmodule ObserverUi.ClusterWatcher do
  @moduledoc """
  Observa el cluster desde afuera, sin que el TP sepa que existe.

  - Descubre los nodos de la máquina preguntándole a `epmd` (el directorio de
    nombres de Erlang), no al cluster.
  - Inspecciona cada nodo con `:erpc` usando solo funciones de Erlang/OTP
    (`:erlang.nodes/0`, `:application.which_applications/0`, `:os.getpid/0`),
    así que no hace falta ningún código del lado del TP.
  - Este nodo es *hidden*, por lo que no aparece en el `Node.list()` de los
    nodos observados y no altera la topología que muestra.

  Cada `poll_interval` arma un snapshot y, si cambió, lo publica a los
  suscriptores (los navegadores conectados por SSE).
  """
  use GenServer

  @max_events 100
  @rpc_timeout 1_000
  # Si un nodo pedido no aparece en este tiempo, se deja de mostrar como "iniciando"
  @pending_ttl_ms 90_000

  ## API

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Snapshot actual del cluster (lo que se manda a la UI)."
  def snapshot, do: GenServer.call(__MODULE__, :snapshot)

  @doc "Suscribe al proceso actual a `{:cluster_snapshot, snapshot}`."
  def subscribe, do: Registry.register(ObserverUi.PubSub, :cluster, nil)

  @doc "Marca un nodo como `:starting` o `:stopping` hasta que el cambio se observe."
  def mark(node, status) when status in [:starting, :stopping],
    do: GenServer.cast(__MODULE__, {:mark, node, status})

  def unmark(node), do: GenServer.cast(__MODULE__, {:unmark, node})

  @doc "Agrega un evento al registro que muestra la UI."
  def log(kind, text), do: GenServer.cast(__MODULE__, {:log, kind, text})

  @doc "¿Es `node` un nodo del TP que está vivo ahora?"
  def target_node?(node), do: GenServer.call(__MODULE__, {:target_node?, node})

  ## Callbacks

  @impl true
  def init(_opts) do
    state = %{
      target_app: Application.fetch_env!(:observer_ui, :target_app),
      interval: Application.fetch_env!(:observer_ui, :poll_interval),
      # nodo => %{name, known, os_pid}
      nodes: %{},
      # nodo => {status, monotonic_ms}
      pending: %{},
      events: [],
      snapshot: nil
    }

    send(self(), :poll)
    {:ok, state}
  end

  @impl true
  def handle_call(:snapshot, _from, state), do: {:reply, build_snapshot(state), state}

  def handle_call({:target_node?, node}, _from, state),
    do: {:reply, Map.has_key?(state.nodes, node), state}

  @impl true
  def handle_cast({:mark, node, status}, state) do
    state = put_in(state.pending[node], {status, now()})
    {:noreply, publish(state)}
  end

  def handle_cast({:unmark, node}, state) do
    {:noreply, state |> Map.update!(:pending, &Map.delete(&1, node)) |> publish()}
  end

  def handle_cast({:log, kind, text}, state) do
    {:noreply, state |> add_events([event(kind, text)]) |> publish()}
  end

  @impl true
  def handle_info(:poll, state) do
    nodes = discover(state.target_app)

    state =
      state
      |> add_events(diff(state.nodes, nodes))
      |> Map.put(:nodes, nodes)
      |> resolve_pending()
      |> publish()

    Process.send_after(self(), :poll, state.interval)
    {:noreply, state}
  end

  ## Descubrimiento e inspección

  defp discover(target_app) do
    candidates()
    |> Task.async_stream(&inspect_node(&1, target_app),
      timeout: @rpc_timeout * 4,
      on_timeout: :kill_task,
      max_concurrency: 32
    )
    |> Enum.flat_map(fn
      {:ok, {:ok, info}} -> [info]
      _ -> []
    end)
    |> Map.new(&{&1.name, &1})
  end

  # Todos los nodos registrados en el epmd local, menos este.
  defp candidates do
    host = local_host()

    case :erl_epmd.names() do
      {:ok, names} ->
        names
        |> Enum.map(fn {name, _port} -> :"#{name}@#{host}" end)
        |> Enum.reject(&(&1 == node()))

      _ ->
        []
    end
  end

  defp inspect_node(node, target_app) do
    apps = :erpc.call(node, :application, :which_applications, [], @rpc_timeout)

    if Enum.any?(apps, fn {app, _desc, _vsn} -> app == target_app end) do
      known = :erpc.call(node, :erlang, :nodes, [], @rpc_timeout)
      os_pid = :erpc.call(node, :os, :getpid, [], @rpc_timeout)
      {:ok, %{name: node, known: Enum.sort(known), os_pid: to_string(os_pid)}}
    else
      :skip
    end
  catch
    _kind, _reason -> :error
  end

  ## Diferencias entre dos observaciones -> eventos

  defp diff(old, new) do
    old_set = MapSet.new(Map.keys(old))
    new_set = MapSet.new(Map.keys(new))

    ups = for n <- MapSet.difference(new_set, old_set), do: event(:up, "#{short(n)} se levantó")
    downs = for n <- MapSet.difference(old_set, new_set), do: event(:down, "#{short(n)} se cayó")

    links =
      for n <- MapSet.intersection(old_set, new_set),
          before = MapSet.new(old[n].known),
          now = MapSet.new(new[n].known),
          event <-
            Enum.map(MapSet.difference(now, before), &event(:link, "#{short(n)} ve a #{short(&1)}")) ++
              Enum.map(
                MapSet.difference(before, now),
                &event(:unlink, "#{short(n)} dejó de ver a #{short(&1)}")
              ),
          do: event

    ups ++ downs ++ links
  end

  # Un "iniciando" se resuelve cuando el nodo aparece; un "bajando", cuando desaparece.
  defp resolve_pending(state) do
    t = now()

    pending =
      state.pending
      |> Enum.reject(fn {node, {status, since}} ->
        up? = Map.has_key?(state.nodes, node)

        (status == :starting and up?) or (status == :stopping and not up?) or
          t - since > @pending_ttl_ms
      end)
      |> Map.new()

    %{state | pending: pending}
  end

  ## Snapshot y publicación

  defp build_snapshot(state) do
    up =
      for {name, info} <- state.nodes do
        status =
          case state.pending[name] do
            {:stopping, _} -> "stopping"
            _ -> "up"
          end

        %{name: name, short: short(name), status: status, os_pid: info.os_pid, known: info.known}
      end

    starting =
      for {name, {:starting, _}} <- state.pending, not Map.has_key?(state.nodes, name) do
        %{name: name, short: short(name), status: "starting", os_pid: nil, known: []}
      end

    %{
      observer: node(),
      nodes: Enum.sort_by(up ++ starting, &sort_key(&1.short)),
      events: state.events
    }
  end

  defp publish(state) do
    snapshot = build_snapshot(state)

    if snapshot != state.snapshot do
      Registry.dispatch(ObserverUi.PubSub, :cluster, fn entries ->
        for {pid, _} <- entries, do: send(pid, {:cluster_snapshot, snapshot})
      end)
    end

    %{state | snapshot: snapshot}
  end

  defp add_events(state, []), do: state

  defp add_events(state, events),
    do: %{state | events: Enum.take(Enum.reverse(events) ++ state.events, @max_events)}

  ## Helpers

  defp event(kind, text) do
    time = DateTime.utc_now() |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()
    %{at: time, kind: kind, text: text}
  end

  def local_host, do: node() |> Atom.to_string() |> String.split("@") |> List.last()

  defp short(node), do: node |> Atom.to_string() |> String.split("@") |> hd()

  # "nodo10" se ordena después de "nodo9"
  defp sort_key(short) do
    case Regex.run(~r/^(.*?)(\d+)$/, short) do
      [_, prefix, n] -> {prefix, String.to_integer(n)}
      _ -> {short, 0}
    end
  end

  defp now, do: System.monotonic_time(:millisecond)
end
