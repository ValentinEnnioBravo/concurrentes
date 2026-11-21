import Config

# libcluster con estrategia Gossip: cada nodo anuncia su nombre por UDP multicast
# y escucha los anuncios de los demás. Cuando oye a uno nuevo, hace Node.connect.
# libcluster NO levanta nodos, solo conecta los que ya están corriendo.
config :libcluster,
  topologies: [
    vuelos: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45892,
        if_addr: "0.0.0.0",
        multicast_if: "0.0.0.0",
        multicast_addr: "230.1.1.251",
        # TTL 1 = el anuncio no sale de la red local
        multicast_ttl: 1
      ]
    ]
  ]

config :logger, :default_formatter, format: "$time [$level] $message\n"
