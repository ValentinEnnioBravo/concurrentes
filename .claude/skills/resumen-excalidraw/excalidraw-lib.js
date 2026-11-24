// Helpers para generar resúmenes de estudio en Excalidraw con el estilo de Resumen/*.excalidraw.
// Uso:  const X = require('<ruta>/excalidraw-lib.js');
//       X.load(archivo)            // opcional: para AGREGAR al final de un resumen existente
//       let y = X.startY();        // 0 si es nuevo; debajo de lo existente si se cargó
//       ... X.header(...), X.section(...), X.side(...), X.qa(...) ...
//       X.save(archivo);  X.check(archivo);
// Chequeo suelto:  node excalidraw-lib.js check "<archivo>"
const fs = require('fs');

const C = {
  BLUE: '#1971c2', BLACK: '#1e1e1e', GRAY: '#868e96', RED: '#e03131', GREEN: '#2f9e44',
  PURPLE: '#9c36b5', VIOLET: '#6741d9', ORANGE: '#e8590c', YELLOW: '#f08c00',
  BG_BLUE: '#e7f5ff', BG_GRAY: '#f8f9fa',
};
const W = 1160;      // ancho de la columna principal
const ANS_X = 1240;  // x de las respuestas punteadas
let E = [];
let seed = 1000;
let doc = null;
const id = () => 'g' + (seed++).toString(36) + Math.random().toString(36).slice(2, 8);

function base(type, x, y, w, h, o = {}) {
  return {
    id: id(), type, x, y, width: w, height: h, angle: 0,
    strokeColor: o.color || C.BLACK, backgroundColor: o.bg || 'transparent',
    fillStyle: 'solid', strokeWidth: o.sw || 2, strokeStyle: o.dashed ? 'dashed' : 'solid',
    roughness: o.r === undefined ? 1 : o.r, opacity: 100, groupIds: [], frameId: null,
    roundness: o.sharp ? null : { type: 3 }, seed: seed++, version: 1, versionNonce: seed++,
    isDeleted: false, boundElements: [], updated: 1795491565091, link: null, locked: false,
  };
}
// Excalifont (5) ≈ 0.56·fs por carácter; Cascadia/mono (3) ≈ 0.6·fs. Alto de línea 1.25·fs.
function measure(str, fs, ff) {
  const lines = str.split('\n');
  const k = ff === 3 ? 0.6 : 0.56;
  return { w: Math.max(...lines.map(l => l.length)) * fs * k, h: lines.length * fs * 1.25 };
}
// Corta un texto en líneas de hasta `max` caracteres (respeta \n y la sangría de viñetas).
function wrap(s, max) {
  return s.split('\n').map(par => {
    const ind = (par.match(/^\s*(•|\d\.|\d\))?\s*/) || [''])[0].replace(/\S/g, ' ');
    const words = par.split(' '); const lines = []; let cur = '';
    words.forEach(w => {
      if ((cur + ' ' + w).length > max && cur.trim()) { lines.push(cur); cur = ind + w; }
      else cur = cur === '' ? w : cur + ' ' + w;
    });
    lines.push(cur); return lines.join('\n');
  }).join('\n');
}
const charsFor = (width, fs = 20, ff = 5) => Math.floor(width / (fs * (ff === 3 ? 0.6 : 0.56)));

// ---------- primitivas ----------
function text(x, y, str, o = {}) {
  const fsz = o.fs || 20, ff = o.ff || 5;
  const m = measure(str, fsz, ff);
  const t = Object.assign(base('text', x, y, m.w, m.h, o), {
    roundness: null, text: str, fontSize: fsz, fontFamily: ff, textAlign: o.align || 'left',
    verticalAlign: 'top', containerId: null, originalText: str, autoResize: true, lineHeight: 1.25,
  });
  E.push(t); return t;
}
function rect(x, y, w, h, o = {}) { const r = base('rectangle', x, y, w, h, o); E.push(r); return r; }
function ellipse(x, y, w, h, o = {}) { const r = base('ellipse', x, y, w, h, o); E.push(r); return r; }
// Rectángulo (o elipse con shape:'ellipse') con texto centrado adentro.
function box(x, y, w, h, str, o = {}) {
  const r = (o.shape === 'ellipse' ? ellipse : rect)(x, y, w, h, o);
  const fsz = o.fs || 18, ff = o.ff || 5;
  const m = measure(str, fsz, ff);
  const t = Object.assign(base('text', x + (w - m.w) / 2, y + (h - m.h) / 2, m.w, m.h, { color: o.tcolor || o.color }), {
    roundness: null, text: str, fontSize: fsz, fontFamily: ff, textAlign: 'center',
    verticalAlign: 'middle', containerId: r.id, originalText: str, autoResize: true, lineHeight: 1.25,
  });
  r.boundElements.push({ type: 'text', id: t.id });
  E.push(t); return r;
}
// Flecha recta (o línea con o.line). o.both = punta en los dos extremos, o.dashed.
function arrow(x1, y1, x2, y2, o = {}) {
  const a = Object.assign(base(o.line ? 'line' : 'arrow', x1, y1, Math.abs(x2 - x1), Math.abs(y2 - y1), o), {
    points: [[0, 0], [x2 - x1, y2 - y1]], startBinding: null, endBinding: null,
    startArrowhead: o.both ? 'arrow' : null, endArrowhead: o.line ? null : 'arrow',
    elbowed: false, lastCommittedPoint: null,
  });
  E.push(a); return a;
}
const line = (x1, y1, x2, y2, o = {}) => arrow(x1, y1, x2, y2, Object.assign({ line: true }, o));

// ---------- bloques del estilo ----------
// Título, pregunta guía, leyenda y "hoja de ruta" de cajitas. Devuelve la y donde arrancar.
function header(title, question, road) {
  text(0, 0, title, { fs: 48 });
  text(0, 80, question, { color: C.BLUE, fs: 26 });
  text(0, 133, '= pregunta para autoevaluarte. La respuesta está a la derecha → en el cuadro punteado: tapala antes\nde leer.', { color: C.PURPLE, fs: 20 });
  const n = road.length, gap = 30, bw = Math.min(200, (W - gap * (n - 1)) / n);
  road.forEach((s, i) => {
    const x = i * (bw + gap);
    box(x, 213, bw, 80, s, { color: C.BLUE, fs: 17 });
    if (i < n - 1) arrow(x + bw + 2, 253, x + bw + gap - 2, 253, { color: C.BLUE });
  });
  return 363;
}
function section(y, title) { box(0, y, W, 95, title, { color: C.BLUE, fs: 34 }); return y + 135; }
// Etiqueta lateral azul a la izquierda (x = -190).
function side(y, label) { const n = label.split('\n').length; box(-190, y, 160, n * 23 + 30, label, { color: C.BLUE, fs: 18 }); }
// Párrafo a todo el ancho (se corta solo). Devuelve la y siguiente.
function para(y, str, o = {}) {
  const x = o.x || 0, fsz = o.fs || 20, width = o.w || W - x;
  const t = text(x, y, wrap(str, charsFor(width, fsz)), { fs: fsz, color: o.color });
  return y + t.height + (o.gap === undefined ? 25 : o.gap);
}
// Bloque de código gris (fuente mono 16). label opcional arriba en gris. Devuelve la y del final.
function code(x, y, w, str, label) {
  if (label) { text(x, y, label, { color: C.GRAY, fs: 18 }); y += 30; }
  const m = measure(str, 16, 3);
  rect(x, y, w, m.h + 30, { color: C.GRAY, bg: C.BG_GRAY, sw: 1, r: 0, sharp: true });
  text(x + 20, y + 15, str, { ff: 3, fs: 16 });
  return y + m.h + 30;
}
// Nota punteada (roja = trampa/advertencia, azul = aclaración). Devuelve la y siguiente.
function note(y, str, color = C.RED, o = {}) {
  const x = o.x || 0, width = o.w || W - x;
  const s = wrap(str, charsFor(width - 50, 20));
  const m = measure(s, 20, 5);
  rect(x, y, width, m.h + 30, { color, dashed: true });
  text(x + 25, y + 15, s, { color, fs: 20 });
  return y + m.h + 30 + (o.gap === undefined ? 30 : o.gap);
}
// Recuadro celeste lleno (analogías, ideas clave).
function callout(y, str, o = {}) {
  const x = o.x || 0, width = o.w || W - x;
  const s = wrap(str, charsFor(width - 50, 20));
  const m = measure(s, 20, 5);
  rect(x, y, width, m.h + 30, { color: C.BLUE, bg: C.BG_BLUE });
  text(x + 25, y + 15, s, { fs: 20 });
  return y + m.h + 30 + (o.gap === undefined ? 30 : o.gap);
}
// Tarjeta con título de color + cuerpo. Devuelve el alto usado.
function card(x, y, w, title, body, color = C.BLACK, o = {}) {
  const fsz = o.fs || 18;
  const s = wrap(body, charsFor(w - 36, fsz));
  const h = o.h || (measure(s, fsz, 5).h + 70);
  rect(x, y, w, h, { color });
  text(x + 18, y + 14, title, { color, fs: o.tfs || 22 });
  text(x + 18, y + 52, s, { fs: fsz });
  return h;
}
// Varias tarjetas en fila (mismo alto). items = [[titulo, cuerpo, color], ...]
function cards(y, items, o = {}) {
  const x0 = o.x || 0, width = o.w || W - x0, gap = o.gap || 30, n = items.length;
  const cw = (width - gap * (n - 1)) / n, fsz = o.fs || 18;
  const h = Math.max(...items.map(([, b]) => measure(wrap(b, charsFor(cw - 36, fsz)), fsz, 5).h + 70));
  items.forEach(([t, b, c], i) => card(x0 + i * (cw + gap), y, cw, t, b, c || C.BLACK, { h, fs: fsz, tfs: o.tfs }));
  return y + h + 30;
}
// Tabla. cols = [[x, ancho], ...]; la 1ª columna va en violeta sobre gris claro.
function table(y, cols, hdr, rows, o = {}) {
  const fsz = o.fs || 18, hh = o.hh || 50;
  cols.forEach(([x, w], i) => {
    rect(x, y, w, hh, { color: C.BLUE, bg: C.BG_BLUE, sw: 1, r: 0, sharp: true });
    text(x + 10, y + (hh - 25) / 2, hdr[i], { color: C.BLUE, fs: o.hfs || 19 });
  });
  y += hh;
  rows.forEach(r => {
    const cells = r.map((s, i) => wrap(s, charsFor(cols[i][1] - 20, fsz)));
    const lines = Math.max(...cells.map(s => s.split('\n').length));
    const h = lines * fsz * 1.25 + 20;
    cells.forEach((s, i) => {
      const [x, w] = cols[i];
      rect(x, y, w, h, { color: C.GRAY, bg: i === 0 ? C.BG_GRAY : 'transparent', sw: 1, r: 0, sharp: true });
      const c = (o.colors && o.colors[i]) || (i === 0 ? C.VIOLET : C.BLACK);
      text(x + 10, y + 10, s, { color: c, fs: fsz });
    });
    y += h;
  });
  return y + (o.gap === undefined ? 30 : o.gap);
}
// Columnas de tabla repartidas en un ancho: widths = [proporciones].
function cols(widths, x0 = 0, total = W) {
  const sum = widths.reduce((a, b) => a + b, 0); let x = x0;
  return widths.map(w => { const ww = Math.round(total * w / sum); const c = [x, ww]; x += ww; return c; });
}
// Flujo horizontal de cajas con flechas. steps = [[texto, color], ...]
function flow(y, steps, o = {}) {
  const x0 = o.x || 0, width = o.w || W - x0, gap = o.gap || 30, n = steps.length;
  const bw = (width - gap * (n - 1)) / n, fsz = o.fs || 17;
  const h = o.h || Math.max(...steps.map(([s]) => measure(s, fsz, 5).h)) + 40;
  steps.forEach(([s, c], i) => {
    const x = x0 + i * (bw + gap);
    box(x, y, bw, h, s, { color: c || C.BLACK, tcolor: C.BLACK, fs: fsz });
    if (i < n - 1) arrow(x + bw + 3, y + h / 2, x + bw + gap - 3, y + h / 2, { color: C.GRAY });
  });
  return y + h + 30;
}
// Pregunta violeta a la izquierda + respuesta gris punteada a la derecha (x=1240).
function qa(y, q, a) {
  const t = text(20, y, q, { color: C.PURPLE, fs: 20 });
  const aw = wrap(a, 46);
  const m = measure(aw, 18, 5);
  const h = Math.max(60, m.h + 30);
  rect(ANS_X, y - 5, 520, h, { color: C.GRAY, dashed: true });
  text(ANS_X + 20, y + 10, aw, { color: C.GRAY, fs: 18 });
  arrow(20 + t.width + 15, y + 12, ANS_X - 10, y + 12, { color: C.GRAY, dashed: true });
  return y + Math.max(h, t.height) + 25;
}
// Pregunta + respuesta debajo (para layouts en 2 columnas, ancho w).
function qaBelow(x, y, w, q, a) {
  const t = text(x, y, wrap(q, charsFor(w, 18)), { color: C.PURPLE, fs: 18 });
  y += t.height + 8;
  const aw = wrap(a, charsFor(w - 32, 17));
  const m = measure(aw, 17, 5);
  rect(x, y, w, m.h + 22, { color: C.GRAY, dashed: true });
  text(x + 16, y + 11, aw, { color: C.GRAY, fs: 17 });
  return y + m.h + 22 + 22;
}

// ---------- archivo ----------
function load(file) {
  const raw = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  doc = raw.trim() ? JSON.parse(raw) : null;
  E = doc ? doc.elements.slice() : [];
  return E;
}
// y donde seguir: 0 si está vacío, o debajo de lo último + margen.
function startY(margin = 130) {
  const live = E.filter(e => !e.isDeleted);
  return live.length ? Math.max(...live.map(e => e.y + e.height)) + margin : 0;
}
function save(file) {
  const out = doc || { type: 'excalidraw', version: 2, source: 'https://excalidraw.com', elements: [],
    appState: { gridSize: 20, gridStep: 5, gridModeEnabled: false, viewBackgroundColor: '#ffffff' }, files: {} };
  out.elements = E;
  fs.writeFileSync(file, JSON.stringify(out, null, 2));
  return E.length;
}
// Reporta textos que se salen de su recuadro o del ancho de su columna.
function check(file, minY = -Infinity) {
  const d = JSON.parse(fs.readFileSync(file, 'utf8'));
  const els = d.elements.filter(e => !e.isDeleted);
  const R = els.filter(e => e.type === 'rectangle');
  const issues = [];
  els.filter(e => e.type === 'text' && !e.containerId && e.y >= minY).forEach(e => {
    const c = R.filter(b => e.x > b.x && e.y > b.y && e.x < b.x + b.width && e.y < b.y + b.height)
      .sort((a, b) => a.width * a.height - b.width * b.height)[0];
    if (c && (e.x + e.width > c.x + c.width - 4 || e.y + e.height > c.y + c.height - 2))
      issues.push(`sale de su recuadro (y=${Math.round(e.y)}): ${JSON.stringify(e.text.slice(0, 50))}`);
    if (!c && e.x < 1200 && e.x + e.width > W + 5)
      issues.push(`pasa el ancho ${W} (y=${Math.round(e.y)}): ${JSON.stringify(e.text.slice(0, 50))}`);
  });
  els.filter(e => e.containerId && e.y >= minY).forEach(e => {
    const c = els.find(x => x.id === e.containerId); if (!c) return;
    const k = c.type === 'ellipse' ? 0.75 : 1;
    if (e.width > c.width * k - 4 || e.height > c.height * k - 2)
      issues.push(`texto apretado en caja (y=${Math.round(c.y)}): ${JSON.stringify(e.text.slice(0, 40))}`);
  });
  console.log(issues.length ? issues.join('\n') : 'OK: sin desbordes');
  return issues;
}

module.exports = {
  C, W, ANS_X, get E() { return E; }, measure, wrap, charsFor,
  text, rect, ellipse, box, arrow, line,
  header, section, side, para, code, note, callout, card, cards, table, cols, flow, qa, qaBelow,
  load, startY, save, check,
};

if (require.main === module && process.argv[2] === 'check') check(process.argv[3]);
