---
name: resumen-excalidraw
description: Arma (o continúa) un resumen de estudio para el parcial en Resumen/*.excalidraw a partir de un apunte de Clases/*.md, con el estilo visual de los resúmenes existentes (conciso, conceptual, con diagramas, tablas y preguntas de autoevaluación). Usar cuando el usuario pide "un resumen/apunte en excalidraw" de una clase o seguir uno.
---

# Resumen de estudio en Excalidraw

Convierte un apunte de clase (`Clases/N. Tema.md`) en un resumen visual para estudiar (`Resumen/N. Tema.excalidraw`). Los resúmenes se generan con un script de Node que usa `excalidraw-lib.js` (en esta misma carpeta), así quedan con el mismo estilo que los demás.

## Qué contenido va

- **Solo los temas que pide el usuario.** Si lista temas, lo que no lista NO va ("recordá que es un resumen"). Si no lista nada, elegí vos los conceptos centrales de la clase.
- **Conceptual y puntual**: por cada tema, una definición corta (1 párrafo), un mini-diagrama o una tabla comparativa, y una nota de trampa/advertencia si la hay. Nada de ejemplos largos del apunte, instalaciones, demos paso a paso ni código salvo 2–5 líneas que ilustren la idea.
- Comparaciones → **tablas** (✅/❌, "X vs. Y"). Procesos o secuencias → **flujo de cajas con flechas** (no diagramas de secuencia). Estructuras → **mini-dibujos** (cajas, elipses para nodos/bases).
- Cada sección termina con 1–3 **preguntas de autoevaluación** (violeta) con la respuesta en un cuadro punteado gris a la derecha (x=1240), tipo pregunta de parcial.
- Lo que se profundiza en otro apunte se **menciona en una línea** ("→ lo vemos en el apunte de CRDTs").
- Escribí en el mismo español rioplatense de los apuntes, con MAYÚSCULAS para resaltar la palabra clave de cada frase.

## Layout y estilo (lo resuelve la librería)

- Título 48 + pregunta guía azul + leyenda violeta + "hoja de ruta" de cajitas azules (`header`).
- Columna principal de 1160 px de ancho a partir de x=0. Secciones numeradas con un recuadro azul a todo el ancho (`section`). Etiquetas laterales azules en x=-190 para cada subtema (`side`).
- Colores: azul `#1971c2` (estructura, aclaraciones), rojo `#e03131` (trampas, problemas), verde `#2f9e44` (lo bueno/solución), violeta `#6741d9` (1ª columna de tablas), naranja `#e8590c`, gris `#868e96` (código, respuestas). Fuente Excalifont (5); código en mono (3) tamaño 16.
- Cuando el usuario lo pide, se puede salir del molde: **tabla horizontal ancha** hacia la derecha (comparar muchos modelos en columnas) o **dos columnas** de 560 px (x=0 y x=600) para temas que se leen en paralelo; en dos columnas las respuestas van debajo de la pregunta (`qaBelow`).

## Cómo hacerlo

1. Leé el apunte completo de `Clases/` y, si el resumen ya existe, mirá qué secciones tiene (títulos de tamaño ≥ 34). **No pises ediciones del usuario**: para continuar un resumen se carga el archivo y se agrega abajo (`load` + `startY`); hacé un backup en el scratchpad antes.
2. Escribí el script en el scratchpad (no en el repo):

```js
const X = require('c:/Users/Usuario/Desktop/UTN Local/CONCURRENTES/concurrentes/.claude/skills/resumen-excalidraw/excalidraw-lib.js');
const { C } = X;
const FILE = process.argv[2];
X.load(FILE);                       // si es un resumen nuevo, el archivo puede no existir o estar vacío
let y = X.startY();
if (y === 0) y = X.header('Clase 1 · Título corto', '¿Pregunta que responde la clase?', ['Tema 1', 'Tema 2', 'Tema 3']);

y = X.section(y, '1. Primer tema');
X.side(y, 'Concepto');
y = X.para(y, 'Concepto = definición en una o dos frases, con la PALABRA CLAVE en mayúscula.');
y = X.cards(y, [['Ventaja', 'texto…', C.GREEN], ['Desventaja', 'texto…', C.RED]]);
y = X.table(y, X.cols([1, 2, 2]), ['', 'Opción A', 'Opción B'], [['Fila', 'a', 'b']]);
y = X.flow(y, [['Paso 1', C.BLUE], ['Paso 2', C.GREEN]]);
y = X.note(y, 'Trampa típica: …');            // roja; X.note(y, '…', C.BLUE) para aclaraciones
y = X.callout(y, 'Analogía / idea clave …');
y = X.qa(y, '¿Pregunta de parcial?', 'Respuesta corta.');

X.save(FILE);
X.check(FILE);
```

   - Para diagramas a medida usá las primitivas `box`, `rect`, `ellipse`, `arrow`, `line`, `text` (coordenadas absolutas; `box(x, y, w, h, texto, {shape:'ellipse'})` centra el texto).
   - Los textos largos se cortan solos en `para`, `note`, `callout`, `cards` y `table`. En `text` y `box` cortá vos con `\n`.
3. Corré el script contra una **copia** en el scratchpad, revisá la salida de `check` (textos que se salen de su recuadro o del ancho de 1160) y corregí. Recién cuando da OK, copiá al archivo real en `Resumen/` (verificando que el original no cambió desde el backup).
4. No se puede ver renderizado: avisale al usuario que lo abra y señalale qué partes son las más delicadas (diagramas a medida).
5. Al terminar, contale en pocas líneas qué quedó en cada sección y qué dejaste afuera.

Las medidas de texto son aproximadas (0.56·tamaño por carácter en Excalifont); `check` usa la misma estimación, conservadora.
