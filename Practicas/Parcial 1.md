# Parcial 1 (recuerdo de un alumno)

Reconstrucción de memoria de un parcial tomado. Las consignas no son textuales.

## Teórico: Verdadero o Falso, justificar

**1. Para identificar a un proceso de larga vida en un sistema se puede usar el PID.**
Falso. Un proceso mantiene el mismo PID mientras está vivo, pero si se reinicia se le asigna otro PID, así que el inicial ya no sirve para identificarlo. Para eso se usa un nombre lógico (Registry, `{:via, ...}`, Horde.Registry).

**2. En el event loop no puede haber condiciones de carrera porque es monothread.**
Falso. Aunque sea un solo hilo, puede haber condiciones de carrera si los recursos compartidos por distintos callbacks no se protegen con alguna herramienta de sincronización (como un semáforo): una tarea lee, cede el control esperando I/O, otra modifica el mismo dato y la primera lo pisa al volver.

**3. En corrutinas es el SO quien asigna la ejecución.**
Falso. Lo decide el scheduler propio del entorno: en Python, el event loop de asyncio. El SO solo planifica el hilo en el que corre el loop.

**4. La implementación estándar de Ruby permite tener paralelismo.**
Falso. MRI tiene GIL, así que solo un hilo ejecuta código Ruby a la vez. Puede haber esperas de I/O simultáneas, pero no ejecución paralela de código Ruby.

**5. En el paradigma de actores, si se envía un mensaje a un actor que está ocupado procesando otro mensaje, ese mensaje se pierde.**
Falso. El mensaje se encola en el mailbox del actor y se procesa después.

**6. En Elixir el envío de mensajes es asincrónico.**
Verdadero, pero es tramposa. La implementación del envío es asincrónica ("fire and forget"). Lo que confunde es `GenServer.call` / `handle_call`, que hace que el cliente se bloquee esperando la respuesta y parece sincrónico: en realidad es una implementación que bloquea al cliente, mientras el mensaje se sigue enviando y procesando de forma asincrónica.

**7. Pregunta sobre Raft.** (No se recuerda el enunciado.)

**8. Pregunta sobre 2 Phase Commit.** (No se recuerda el enunciado.)

Había dos preguntas más; una era sobre escalamiento o monolitos.

## Práctico: notas compartidas

Plantear una aplicación con **usuarios** y **notas**:

- Las notas tienen un máximo de **200 caracteres** y una **fecha/hora de expiración**.
- Los usuarios pueden **compartir** notas (por ejemplo, el usuario A le manda la nota 1 al usuario B).
- Cada usuario tiene una **lista con todas las notas que le compartieron**.
- Hay que llevar registro de **a qué usuarios se compartió cada nota**, porque cuando una nota expira hay que **avisarle a cada uno** de esos usuarios que una nota que le compartieron va a expirar.

Se pedía:

1. Modelar el **árbol de supervisión**.
2. Describir **qué estado guarda cada proceso**.
3. Relacionarlo con el **teorema CAP** y explicar cómo se maneja la **replicación**.

Básicamente, lo mismo que en el TP. Un enfoque que funcionó: plantear la solución para **un solo nodo** y después explicar en palabras qué cambiaría para distribuirla (`Horde.Registry`, `Horde.DynamicSupervisor`, replicación del estado, qué se elige ante una partición).

Una resolución posible está en el ejercicio 2 de [Simulacro Parcial 1](Simulacro%20Parcial%201.md).
