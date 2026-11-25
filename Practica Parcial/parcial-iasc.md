# Parcial IASC

## Teórico: V o F. Justificar

1. Para identificar a un proceso de larga vida en un sistema se puede usar el PID.

   **Respuesta:**

2. En el event loop no puede haber condiciones de carrera porque es monothread.

   **Respuesta:**

3. En corrutinas es el SO quien asigna la ejecución.

   **Respuesta:**

4. La implementación estándar de Ruby permite tener paralelismo.

   **Respuesta:**

5. En el paradigma de actores, si se envía un mensaje a un actor que está ocupado procesando otro mensaje, este mensaje se pierde.

   **Respuesta:**

6. En Elixir el envío de mensajes es asincrónico.

   **Respuesta:**

7. *(Pregunta sobre Raft: no se recuerda el enunciado)*

   **Respuesta:**

8. *(Pregunta sobre 2 Phase Commit: no se recuerda el enunciado)*

   **Respuesta:**

> Faltan 2 preguntas más que no se recuerdan (posiblemente sobre escalamiento o monolitos).

## Práctico

Se quiere modelar una aplicación con **usuarios** y **notas**:

- Cada nota tiene un texto de **máximo 200 caracteres** y una **fecha/hora de expiración**.
- Los usuarios pueden **compartir notas** con otros usuarios (por ejemplo, el usuario A le manda la nota1 al usuario B).
- Cada usuario tiene una **lista con todas las notas que le compartieron**.
- Se debe llevar un **registro de qué notas se compartieron a qué usuarios**, ya que cuando una nota está por expirar se le tiene que **enviar un mensaje a cada uno de esos usuarios** avisándole que una de las notas que se le compartió va a expirar.

Se pide:

1. Modelar el **árbol de supervisión**.
2. Describir **qué estado se guarda en cada proceso**.
3. Explicar cómo **distribuir** la aplicación en varios nodos.
4. Relacionar la solución con el **Teorema CAP** y explicar cómo se maneja la **replicación**.

### Resolución

**Árbol de supervisión:**

**Estado de cada proceso:**

**Distribución:**

**CAP y replicación:**
