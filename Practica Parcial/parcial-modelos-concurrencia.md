# Parcial: Modelos de concurrencia

Supongamos que, en una arquitectura cliente-servidor, tenemos un programa servidor, que se lanza mediante un script `servidor.sh`, desarrollado en una cierta plataforma tecnológica (3), como por ejemplo:

- **Ruby/MRI**: el lenguaje Ruby ejecutado con el intérprete MRI
- **JRuby**: el lenguaje Ruby corriendo en la JVM
- **Node.js/V8**: Node.js que utiliza Javascript en la máquina virtual V8.
- **Elixir/BEAM**: el lenguaje Elixir corriendo en la máquina virtual BEAM.

Supongamos también que este servidor debe atender múltiples pedidos entrantes y concurrentes, y los atiende empleando un modelo de concurrencia (1) soportado por esta plataforma tecnológica. Y finalmente, lo ejecutamos en un hardware SMP¹ (es decir, multicore) de **4 núcleos**, y **queremos ejecutar la mínima cantidad de procesos del sistema operativo para que podamos aprovecharlos a todos los núcleos disponibles²**.

Sabiendo esto, completá el siguiente cuadro, indicando:

- (2) cuántos procesos deberías ejecutar como mínimo (dicho de otra forma, cuántas veces deberías ejecutar `servidor.sh`);
- (3) qué tecnología permitiría aplicar fácilmente este modelo de concurrencia;
- y (4) si el servidor consultara en cada pedido a una base de datos con un *driver* **bloqueante**, ¿podría **un sólo proceso** continuar atendiendo pedidos?

## Cuadro

| (1) Modelo de concurrencia | (2) Cantidad mínima de procesos | (3) Posibles plataformas tecnológicas | (4) ¿Podrá continuar atendiendo ante un bloqueo de IO? *(Recordar que las llamadas IO son mediante un driver bloqueante)* | Observaciones |
|---|---|---|---|---|
| Sin concurrencia (los pedidos se atienden de a uno por vez) | | | | |
| Orientado a eventos aka Event Loop | | | | |
| Green Threads | | | | El OS los ve como un solo proceso. |
| S.O. Threads | | | | |
| Corrutinas | | | | |
| Paso de mensajes | | | | |
| STM (Software Transactional Memory) | | | | |

---

¹ Symmetric multiprocessing.

² En caso de tener múltiples procesos del sistema operativo, los pedidos que lleguen de los clientes se despacharán apropiadamente por medio de un balanceador de carga entre los clientes y los servidores. Si se tiene un balanceador de carga, se deberá considerar que su procesamiento se lleva a cabo en un procesador y siempre será utilizado por el mismo (no hay expropiación de este recurso por otro proceso).
