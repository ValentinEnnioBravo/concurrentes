import Config

config :observer_ui,
  # Puerto HTTP de la UI
  port: 4000,
  # Solo se muestran los nodos que tengan esta aplicación corriendo.
  # Es lo único que la UI "sabe" del TP.
  target_app: :vuelos,
  # Carpeta del proyecto del TP, desde donde se lanzan los nodos nuevos
  target_path: Path.expand("../../vuelos", __DIR__),
  # Prefijo de los nodos que crea el botón "Agregar nodo" (nodo1, nodo2, ...)
  node_prefix: "nodo",
  # Cada cuánto se inspecciona el cluster (ms)
  poll_interval: 1_000

config :logger, :default_formatter, format: "$time [$level] $message\n"
