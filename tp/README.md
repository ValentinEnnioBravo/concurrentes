# TP vuelos: cluster + observador

```
tp/
├── vuelos/        la solución del TP (por ahora solo libcluster con Gossip)
└── observer_ui/   UI de visualización, totalmente desacoplada del TP
```

## Cómo está desacoplada la UI

El TP **no tiene ninguna línea de código para la UI** y no depende de ella. Si la UI se cae o nadie la mira, el cluster sigue igual.

- `observer_ui` es un nodo Erlang **oculto** (`--hidden`). Se conecta a los nodos para mirarlos, pero no aparece en su `Node.list()`, así que no altera la topología que muestra.
- **Descubre** los nodos preguntándole a `epmd`, el directorio de nombres de la máquina, y no al cluster.
- **Inspecciona** cada nodo con `:erpc` usando solo funciones de Erlang/OTP: `:erlang.nodes/0` para ver a quién conoce, `:application.which_applications/0` para saber si corre `:vuelos` y `:os.getpid/0`.
- **Levantar y bajar nodos** es tarea de infraestructura, como systemd o Kubernetes. El observador lanza un proceso del sistema operativo (`elixir --sname nodoN -S mix run --no-halt`) y para bajarlo llama a `:init.stop()` en el nodo remoto.
- Lo único que la UI sabe del TP está en `observer_ui/config/config.exs`: el nombre de la app (`:vuelos`) y su carpeta.

## Requisitos

Erlang/OTP 26 o superior y Elixir 1.15 o superior. En Windows:

```powershell
winget install -e --id Erlang.ErlangOTP
winget install -e --id Elixir.Elixir
```

## Cómo correrlo

Primero se compila el TP una vez, para que los nodos que se lancen no compilen todos a la vez:

```bash
cd tp/vuelos
mix deps.get
mix compile
```

Después se levanta el observador, **con la misma cookie** que el cluster:

```bash
cd tp/observer_ui
mix deps.get
iex --sname observer --cookie secreto --hidden -S mix
```

Abrí http://localhost:4000.

- **+ Agregar nodo** levanta `nodo1`, `nodo2`, …. La salida de cada nodo queda en `observer_ui/logs/nodoN.log`.
- **Dar de baja** apaga ese nodo de forma ordenada (`:init.stop`).
- También aparecen los nodos que levantes a mano, siempre que usen la misma cookie:

  ```bash
  cd tp/vuelos
  iex --sname a --cookie secreto -S mix
  ```

## Qué se ve

- **Topología:** un grafo con los nodos. La línea llena significa que los dos se ven, y la punteada con flecha que solo uno ve al otro, algo transitorio mientras Gossip los conecta.
- **Tarjeta por nodo:** su nombre, el estado, a quién conoce (`:erlang.nodes()` de ese nodo) y si ve a todo el cluster.
- **Eventos:** se levantó o se cayó un nodo, o "A ve a B" / "A dejó de ver a B", desde el punto de vista de cada nodo.

Gossip anuncia cada nodo cada ~5 s, así que un nodo nuevo tarda unos segundos en conectarse con los demás.

## Problemas comunes

- **Los nodos aparecen pero no se ven entre sí:** el multicast UDP (230.1.1.251:45892) está bloqueado. En Windows, permití `erl.exe` en el firewall cuando aparezca el aviso. Si hay varios adaptadores de red (Docker, WSL o VPN), puede salir por el adaptador equivocado: probá con `multicast_if` igual a la IP de tu adaptador principal en `vuelos/config/config.exs`.
- **No aparece ningún nodo:** revisá que la cookie sea la misma y que el observador se haya levantado con `--sname`.
- **Un nodo queda "iniciando…" y desaparece:** mirá `observer_ui/logs/nodoN.log`.
