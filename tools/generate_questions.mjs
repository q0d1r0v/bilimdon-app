#!/usr/bin/env node
// Savol generatori — assets/content/ch1.json..ch3.json fayllarini yozadi.
// Deterministik: mulberry32 PRNG, urug' = daraja id ("1-4") FNV-1a xeshi,
// shuning uchun har ishga tushirishda natija aynan bir xil.
//
// Ishga tushirish:
//   node tools/generate_questions.mjs
//
// Global qoidalar:
//   - har savolda aynan 4 ta har xil javob;
//   - to'g'ri javob o'rni urug'langan aralashtirish bilan tekis taqsimlanadi
//     (sanashda — n ni o'z ichiga olgan ketma-ket oyna, prototipdagidek);
//   - manfiy son yo'q, raqamli javoblar 0..20;
//   - to'g'ri javob > 5 bo'lsa, distraktor 2 barobaridan oshmaydi;
//   - 1-3 daraja — DESIGN_SPEC.md prototip savollari AYNAN (aralashtirilmaydi):
//     "shuffleAnswers": false chiqariladi, runtime ham qayta aralashtirmaydi.

import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const OUT_DIR = join(
  dirname(fileURLToPath(import.meta.url)),
  '..',
  'assets',
  'content',
);
const SCHEMA_VERSION = 2;
const QUESTIONS_PER_LEVEL = 5;
const ANIMALS = ['chick', 'sheep', 'pig'];
const SHAPES = ['triangle', 'circle', 'square', 'diamond'];

// ---------- Deterministik PRNG ----------

/** FNV-1a 32-bit satr xeshi — daraja id dan urug'. */
function fnv1a(str) {
  let h = 0x811c9dc5;
  for (let i = 0; i < str.length; i += 1) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}

/** mulberry32 — kichik, sifatli, deterministik PRNG. */
function mulberry32(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const randInt = (rng, min, max) => min + Math.floor(rng() * (max - min + 1));

/** Fisher–Yates, urug'langan. */
function shuffled(rng, items) {
  const arr = [...items];
  for (let i = arr.length - 1; i > 0; i -= 1) {
    const j = Math.floor(rng() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

const range = (from, to) =>
  Array.from({ length: to - from + 1 }, (_, i) => from + i);
const pickN = (rng, items, n) => shuffled(rng, items).slice(0, n);

// ---------- Javob qatorlarini yig'ish ----------

/** Global distraktor filtri: 0..20, correct'dan farqli, 2x qoidasi. */
const isValidDistractor = (v, correct) =>
  Number.isInteger(v) &&
  v >= 0 &&
  v <= 20 &&
  v !== correct &&
  (correct <= 5 || v <= 2 * correct);

/**
 * Raqamli javob qatori: correct + hovuzdan 3 ta distraktor (urug'langan),
 * so'ng butun qator urug'langan aralashtiriladi. `forced` — imkon boricha
 * albatta kiritiladigan distraktorlar (masalan ayirishda a+b).
 */
function numberAnswers(rng, correct, pool, forced = []) {
  const seen = new Set([correct]);
  const distractors = [];
  const push = (v) => {
    if (
      distractors.length < 3 &&
      isValidDistractor(v, correct) &&
      !seen.has(v)
    ) {
      seen.add(v);
      distractors.push(v);
    }
  };
  forced.forEach(push);
  shuffled(rng, pool).forEach(push);
  // Zaxira: hovuz yetmasa, correct atrofini kengaytirib to'ldiramiz.
  for (let d = 3; distractors.length < 3 && d <= 20; d += 1) {
    push(correct - d);
    push(correct + d);
  }
  const order = shuffled(rng, [correct, ...distractors]);
  return {
    answers: order.map((number) => ({ number })),
    correctIndex: order.indexOf(correct),
  };
}

/**
 * Sanash: n ni o'z ichiga olgan 4 talik KETMA-KET oyna, boshi tasodifiy,
 * hammasi >= 1 (prototip: 4 → [3,4,5,6]).
 */
function countingAnswers(rng, n) {
  const start = randInt(rng, Math.max(1, n - 3), n);
  return {
    answers: range(start, start + 3).map((number) => ({ number })),
    correctIndex: n - start,
  };
}

// ---------- Savol quruvchilar ----------

function makeCounting(rng, id, animal, n) {
  return {
    id,
    type: 'counting',
    data: { animal },
    visual: { kind: 'count', animal, count: n },
    ...countingAnswers(rng, n),
  };
}

function makeAddition(rng, id, a, b) {
  const c = a + b;
  const visual =
    c <= 12
      ? { kind: 'grouped', animal: 'pig', groups: [a, b] }
      : { kind: 'tenFrame', groups: [a, b] };
  return {
    id,
    type: 'addition',
    data: { a, b, missing: 'none' },
    visual,
    ...numberAnswers(rng, c, [c - 1, c + 1, c - 2, c + 2, a, b]),
  };
}

function makeSubtraction(rng, id, a, b) {
  const c = a - b;
  const visual =
    a <= 12
      ? { kind: 'faded', animal: 'sheep', count: a, faded: b }
      : { kind: 'tenFrame', groups: [a], faded: b };
  // a+b — "amalni adashtirish" distraktori: 20 dan oshmasa doim kiradi.
  return {
    id,
    type: 'subtraction',
    data: { a, b, missing: 'none' },
    visual,
    ...numberAnswers(rng, c, [c - 1, c + 1, c + 2, b, a], [a + b]),
  };
}

/** Yetishmayotgan operand: a + ? = c yoki a − ? = c (javob — b). */
function makeMissing(rng, id, op, a, b) {
  const c = op === 'addition' ? a + b : a - b;
  // Ikki amalda ham ramkada NATIJAga qadar to'ldirilgan kataklar ko'rsatiladi,
  // qolgani sariq halqa: a + ? = c → a ta to'la, halqa c gacha;
  // a − ? = c → c ta to'la, halqa a gacha (javob = a − c).
  const filled = op === 'addition' ? a : c;
  const goal = op === 'addition' ? c : a;
  return {
    id,
    type: op,
    data: { a, b, missing: 'b', c },
    visual: { kind: 'tenFrame', groups: [filled], target: goal },
    ...numberAnswers(rng, b, [b - 1, b + 1, b - 2, b + 2, a, c]),
  };
}

function makeShapes(rng, id, target) {
  const order = shuffled(rng, SHAPES);
  return {
    id,
    type: 'shapes',
    data: { target },
    visual: { kind: 'none' },
    answers: order.map((shape) => ({ shape })),
    correctIndex: order.indexOf(target),
  };
}

function makeSequence(rng, id, terms, next) {
  const last = terms[terms.length - 1];
  return {
    id,
    type: 'sequence',
    data: { terms },
    visual: { kind: 'numberLine', terms, step: terms[1] - terms[0] },
    ...numberAnswers(rng, next, [
      next - 1,
      next + 1,
      next + 2,
      next - 2,
      last + 1,
    ]),
  };
}

function makeComparison(rng, id, mode) {
  let numbers;
  if (mode === 'smallest') {
    const low = randInt(rng, 5, 9);
    // 2x qoidasi: correct > 5 bo'lsa boshqalar 2*low dan oshmasin.
    const hi = low > 5 ? Math.min(20, 2 * low) : 20;
    numbers = [low, ...pickN(rng, range(low + 1, hi), 3)];
  } else {
    const high = randInt(rng, 12, 20);
    numbers = [high, ...pickN(rng, range(5, high - 1), 3)];
  }
  const order = shuffled(rng, numbers);
  const correct =
    mode === 'smallest' ? Math.min(...order) : Math.max(...order);
  return {
    id,
    type: 'comparison',
    data: { mode },
    visual: { kind: 'bars', values: order },
    answers: order.map((number) => ({ number })),
    correctIndex: order.indexOf(correct),
  };
}

// ---------- Parametrlangan yordamchilar ----------

/** Qo'shish: a,b >= 1, c <= 10 (grouped vizual kafolatlanadi). */
function additionEasy(rng, id) {
  const a = randInt(rng, 1, 8);
  const b = randInt(rng, 1, 10 - a);
  return makeAddition(rng, id, a, b);
}

/** Qo'shish qiyinroq: c 8..14. */
function additionHarder(rng, id) {
  const a = randInt(rng, 3, 9);
  const b = randInt(rng, Math.max(1, 8 - a), Math.min(9, 14 - a));
  return makeAddition(rng, id, a, b);
}

/** Ayirish: a ∈ [minA..maxA], b ∈ [1..a-1] (natija >= 1). */
function subtractionIn(rng, id, minA, maxA) {
  const a = randInt(rng, minA, maxA);
  const b = randInt(rng, 1, a - 1);
  return makeSubtraction(rng, id, a, b);
}

/** Ketma-ketlik 11..20: qadam +1 yoki +2, javob 12..20. */
function sequenceTeen(rng, id) {
  const step = randInt(rng, 1, 2);
  const next = step === 1 ? randInt(rng, 12, 20) : randInt(rng, 14, 20);
  const start = next - 3 * step;
  return makeSequence(rng, id, [start, start + step, start + 2 * step], next);
}

/** Qo'shish natijasi <= maxC (balanslangan a,b; c > 12 da vizualsiz). */
function additionTo(rng, id, maxC) {
  const c = randInt(rng, Math.max(6, maxC - 5), maxC);
  const a = randInt(rng, Math.max(2, c - 10), Math.min(10, c - 2));
  return makeAddition(rng, id, a, c - a);
}

/** Ko'paytirish: a × b, mahsulot <= 20, vizualsiz (prompt "a × b = ?"). */
function makeMultiplication(rng, id, a, b) {
  const c = a * b;
  return {
    id,
    type: 'multiplication',
    data: { a, b },
    // a <= 3 && b <= 10 — aks holda vizual balandlik budjetiga sig'maydi
    // (test/visual_hint_test.dart dagi sweep buni qo'riqlaydi).
    visual:
      a <= 3 && b <= 10
        ? { kind: 'groupRows', animal: 'chick', groups: Array(a).fill(b) }
        : { kind: 'none' },
    ...numberAnswers(rng, c, [c - a, c + a, c - b, c + b, a + b, c - 2, c + 2]),
  };
}

/** a jadvalidan tasodifiy ko'paytirish (a × b, mahsulot <= 20, b >= 2). */
function multBy(rng, id, a) {
  const b = randInt(rng, 2, Math.min(9, Math.floor(20 / a)));
  return makeMultiplication(rng, id, a, b);
}

// ---------- 1-3: DESIGN_SPEC.md prototip savollari AYNAN ----------

function prototypeQuestions(qid) {
  const num = (values) => values.map((number) => ({ number }));
  return [
    {
      id: qid(1),
      type: 'counting',
      data: { animal: 'chick' },
      visual: { kind: 'count', animal: 'chick', count: 4 },
      answers: num([3, 4, 5, 6]),
      correctIndex: 1,
    },
    {
      id: qid(2),
      type: 'addition',
      data: { a: 3, b: 2, missing: 'none' },
      visual: { kind: 'grouped', animal: 'pig', groups: [3, 2] },
      answers: num([4, 5, 6, 3]),
      correctIndex: 1,
    },
    {
      id: qid(3),
      type: 'shapes',
      data: { target: 'triangle' },
      visual: { kind: 'none' },
      answers: SHAPES.map((shape) => ({ shape })),
      correctIndex: 0,
    },
    {
      id: qid(4),
      type: 'subtraction',
      data: { a: 5, b: 2, missing: 'none' },
      visual: { kind: 'faded', animal: 'sheep', count: 5, faded: 2 },
      answers: num([2, 3, 4, 6]),
      correctIndex: 1,
    },
    {
      id: qid(5),
      type: 'sequence',
      data: { terms: [2, 4, 6] },
      visual: { kind: 'none' },
      answers: num([7, 8, 10, 9]),
      correctIndex: 1,
    },
  ];
}

// ---------- O'quv dasturi (har darajada 5 savol) ----------

const LEVEL_DEFS = [
  // === 1-BOB: Sanash va qo'shish (taymersiz) ===
  {
    id: '1-1', // sanash 2..5, hayvonlar: jo'ja, qo'y, cho'chqa, jo'ja, jo'ja
    build: (rng, qid) =>
      ['chick', 'sheep', 'pig', 'chick', 'chick'].map((animal, i) =>
        makeCounting(rng, qid(i + 1), animal, randInt(rng, 2, 5)),
      ),
  },
  {
    id: '1-2', // sanash 4..10
    build: (rng, qid) =>
      range(1, 5).map((i) =>
        makeCounting(rng, qid(i), ANIMALS[(i - 1) % 3], randInt(rng, 4, 10)),
      ),
  },
  {
    id: '1-3', // prototip — aynan, aralashtirishsiz (runtime ham)
    shuffleAnswers: false,
    build: (rng, qid) => prototypeQuestions(qid),
  },
  {
    id: '1-4', // qo'shish, c <= 10, grouped vizual
    build: (rng, qid) => range(1, 5).map((i) => additionEasy(rng, qid(i))),
  },
  {
    id: '1-5', // aralash: sanash + qo'shish
    build: (rng, qid) => [
      makeCounting(rng, qid(1), 'chick', randInt(rng, 3, 9)),
      additionEasy(rng, qid(2)),
      makeCounting(rng, qid(3), 'sheep', randInt(rng, 3, 9)),
      additionEasy(rng, qid(4)),
      additionEasy(rng, qid(5)),
    ],
  },
  {
    id: '1-6', // takrorlash, biroz qiyinroq
    build: (rng, qid) => [
      makeCounting(rng, qid(1), 'pig', randInt(rng, 7, 12)),
      additionHarder(rng, qid(2)),
      additionHarder(rng, qid(3)),
      makeCounting(rng, qid(4), 'chick', randInt(rng, 7, 12)),
      additionHarder(rng, qid(5)),
    ],
  },

  // === 2-BOB: Ayirish va ketma-ketlik (faqat 2-5 taymerli) ===
  {
    id: '2-1', // ayirish a <= 5, faded qo'y vizual
    build: (rng, qid) => range(1, 5).map((i) => subtractionIn(rng, qid(i), 2, 5)),
  },
  {
    id: '2-2', // ayirish a <= 10
    build: (rng, qid) =>
      range(1, 5).map((i) => subtractionIn(rng, qid(i), 4, 10)),
  },
  {
    id: '2-3', // aralash qo'shish/ayirish <= 10
    build: (rng, qid) => [
      additionEasy(rng, qid(1)),
      subtractionIn(rng, qid(2), 4, 10),
      additionEasy(rng, qid(3)),
      subtractionIn(rng, qid(4), 4, 10),
      additionEasy(rng, qid(5)),
    ],
  },
  {
    id: '2-4', // ketma-ketlik 11..20, vizualsiz
    build: (rng, qid) => range(1, 5).map((i) => sequenceTeen(rng, qid(i))),
  },
  {
    id: '2-5', // tezkor raund — taymer 15s
    timerSeconds: 15,
    build: (rng, qid) => [
      makeCounting(rng, qid(1), 'chick', randInt(rng, 3, 8)),
      additionEasy(rng, qid(2)),
      subtractionIn(rng, qid(3), 3, 8),
      additionEasy(rng, qid(4)),
      subtractionIn(rng, qid(5), 3, 8),
    ],
  },
  {
    id: '2-6', // takrorlash
    build: (rng, qid) => [
      subtractionIn(rng, qid(1), 5, 12),
      additionHarder(rng, qid(2)),
      sequenceTeen(rng, qid(3)),
      subtractionIn(rng, qid(4), 5, 12),
      additionHarder(rng, qid(5)),
    ],
  },

  // === 3-BOB: Shakllar, mantiq, taqqoslash ===
  {
    id: '3-1', // shakllar (rombsiz maqsadlar)
    // Romb ATAYLAB kiritilmaydi (u 3-2 da tanishtiriladi) → 3 shakl, 5 savol,
    // ya'ni kamida 2 takror MUQARRAR (kaptar uyasi qoidasi). Takrorlar teng
    // taqsimlangan (2+2+1) va javob pozitsiyasi har savolda aralashtiriladi.
    allowedRepeats: 2,
    build: (rng, qid) =>
      ['triangle', 'circle', 'square', 'triangle', 'circle'].map(
        (target, i) => makeShapes(rng, qid(i + 1), target),
      ),
  },
  {
    id: '3-2', // shakllar + romb
    // 4 shakl, 5 savol → 1 takror muqarrar. Romb — yangi shakl, shuning uchun
    // aynan u ikki marta (boshi va oxiri) so'raladi; qolgan uchtasi bir marta.
    allowedRepeats: 1,
    build: (rng, qid) =>
      ['diamond', 'triangle', 'square', 'circle', 'diamond'].map(
        (target, i) => makeShapes(rng, qid(i + 1), target),
      ),
  },
  {
    id: '3-3', // ketma-ketlik: +1, +2, +5, -1, +2 (qo'lda sozlangan)
    build: (rng, qid) =>
      [
        [[3, 4, 5], 6],
        [[4, 6, 8], 10],
        [[5, 10, 15], 20],
        [[10, 9, 8], 7],
        [[6, 8, 10], 12],
      ].map(([terms, next], i) => makeSequence(rng, qid(i + 1), terms, next)),
  },
  {
    id: '3-4', // yetishmayotgan operand: 3 + ? = 7 (promptni UI quradi)
    build: (rng, qid) =>
      range(1, 5).map((i) => {
        if (i % 2 === 1) {
          const a = randInt(rng, 2, 9);
          const b = randInt(rng, 2, Math.min(7, 15 - a));
          return makeMissing(rng, qid(i), 'addition', a, b);
        }
        const b = randInt(rng, 2, 6);
        const c = randInt(rng, 2, 9);
        return makeMissing(rng, qid(i), 'subtraction', b + c, b);
      }),
  },
  {
    id: '3-5', // taqqoslash: 4 ta son 5..20 ichidan eng katta/kichigi
    build: (rng, qid) =>
      ['biggest', 'smallest', 'biggest', 'smallest', 'biggest'].map(
        (mode, i) => makeComparison(rng, qid(i + 1), mode),
      ),
  },
  {
    id: '3-6', // katta aralash raund — taymer 10s
    timerSeconds: 10,
    build: (rng, qid) => [
      (() => {
        const a = randInt(rng, 6, 12);
        const b = randInt(rng, 3, Math.min(8, 18 - a));
        return makeAddition(rng, qid(1), a, b);
      })(),
      subtractionIn(rng, qid(2), 9, 15),
      sequenceTeen(rng, qid(3)),
      makeComparison(rng, qid(4), 'biggest'),
      makeShapes(rng, qid(5), SHAPES[randInt(rng, 0, 3)]),
    ],
  },

  // === 4-BOB: Sonlar 20 gacha (ko'lmak) ===
  {
    id: '4-1', // ketma-ketlik 11..20
    build: (rng, qid) => range(1, 5).map((i) => sequenceTeen(rng, qid(i))),
  },
  {
    id: '4-2', // taqqoslash 5..20
    build: (rng, qid) =>
      ['biggest', 'smallest', 'biggest', 'smallest', 'biggest'].map((m, i) =>
        makeComparison(rng, qid(i + 1), m),
      ),
  },
  {
    id: '4-3', // aralash ketma-ketlik + taqqoslash
    build: (rng, qid) => [
      sequenceTeen(rng, qid(1)),
      makeComparison(rng, qid(2), 'biggest'),
      sequenceTeen(rng, qid(3)),
      makeComparison(rng, qid(4), 'smallest'),
      sequenceTeen(rng, qid(5)),
    ],
  },
  {
    id: '4-4', // qo'shish 15 gacha
    build: (rng, qid) => range(1, 5).map((i) => additionTo(rng, qid(i), 15)),
  },
  {
    id: '4-5', // aralash
    build: (rng, qid) => [
      additionTo(rng, qid(1), 15),
      sequenceTeen(rng, qid(2)),
      additionTo(rng, qid(3), 15),
      makeComparison(rng, qid(4), 'biggest'),
      additionTo(rng, qid(5), 15),
    ],
  },
  {
    id: '4-6', // bob sinovi
    build: (rng, qid) => [
      sequenceTeen(rng, qid(1)),
      additionTo(rng, qid(2), 18),
      makeComparison(rng, qid(3), 'biggest'),
      sequenceTeen(rng, qid(4)),
      additionTo(rng, qid(5), 18),
    ],
  },

  // === 5-BOB: Qo'shish-ayirish 20 gacha (dala) ===
  {
    id: '5-1', // qo'shish 15 gacha
    build: (rng, qid) => range(1, 5).map((i) => additionTo(rng, qid(i), 15)),
  },
  {
    id: '5-2', // qo'shish 20 gacha
    build: (rng, qid) => range(1, 5).map((i) => additionTo(rng, qid(i), 20)),
  },
  {
    id: '5-3', // ayirish 15 gacha
    build: (rng, qid) => range(1, 5).map((i) => subtractionIn(rng, qid(i), 8, 15)),
  },
  {
    id: '5-4', // ayirish 20 gacha
    build: (rng, qid) =>
      range(1, 5).map((i) => subtractionIn(rng, qid(i), 12, 20)),
  },
  {
    id: '5-5', // tezkor raund — taymer 15s
    timerSeconds: 15,
    build: (rng, qid) => [
      additionTo(rng, qid(1), 18),
      subtractionIn(rng, qid(2), 8, 15),
      additionTo(rng, qid(3), 18),
      subtractionIn(rng, qid(4), 8, 15),
      additionTo(rng, qid(5), 18),
    ],
  },
  {
    id: '5-6', // bob sinovi
    build: (rng, qid) => [
      additionTo(rng, qid(1), 20),
      subtractionIn(rng, qid(2), 12, 20),
      additionTo(rng, qid(3), 20),
      subtractionIn(rng, qid(4), 12, 20),
      makeComparison(rng, qid(5), 'biggest'),
    ],
  },

  // === 6-BOB: Ko'paytirish (bog') ===
  {
    id: '6-1', // 2× jadval
    build: (rng, qid) => range(1, 5).map((i) => multBy(rng, qid(i), 2)),
  },
  {
    id: '6-2', // 3× jadval
    build: (rng, qid) => range(1, 5).map((i) => multBy(rng, qid(i), 3)),
  },
  {
    id: '6-3', // guruhlar — kichik ko'paytmalar
    build: (rng, qid) => [
      makeMultiplication(rng, qid(1), 2, 2),
      makeMultiplication(rng, qid(2), 2, 3),
      makeMultiplication(rng, qid(3), 3, 2),
      makeMultiplication(rng, qid(4), 3, 3),
      makeMultiplication(rng, qid(5), 2, 4),
    ],
  },
  {
    id: '6-4', // aralash amallar
    build: (rng, qid) => [
      multBy(rng, qid(1), 2),
      additionTo(rng, qid(2), 18),
      multBy(rng, qid(3), 3),
      subtractionIn(rng, qid(4), 10, 18),
      multBy(rng, qid(5), 2),
    ],
  },
  {
    id: '6-5', // katta taqqoslash
    build: (rng, qid) =>
      ['biggest', 'smallest', 'biggest', 'smallest', 'biggest'].map((m, i) =>
        makeComparison(rng, qid(i + 1), m),
      ),
  },
  {
    id: '6-6', // katta sinov — taymer 12s
    timerSeconds: 12,
    build: (rng, qid) => [
      multBy(rng, qid(1), 2),
      multBy(rng, qid(2), 3),
      additionTo(rng, qid(3), 20),
      subtractionIn(rng, qid(4), 12, 20),
      makeComparison(rng, qid(5), 'biggest'),
    ],
  },
];

// ---------- O'z-o'zini tekshirish ----------

function validateQuestion(q) {
  const fail = (msg) => {
    throw new Error(`savol ${q.id}: ${msg}`);
  };
  if (q.answers.length !== 4) fail('aynan 4 ta javob kerak');
  if (
    !Number.isInteger(q.correctIndex) ||
    q.correctIndex < 0 ||
    q.correctIndex > 3
  ) {
    fail(`correctIndex 0..3 emas: ${q.correctIndex}`);
  }
  const keys = q.answers.map((cell) => `${cell.number ?? ''}|${cell.shape ?? ''}`);
  if (new Set(keys).size !== 4) fail(`javoblar takrorlangan: ${keys}`);
  for (const cell of q.answers) {
    const hasNumber = cell.number !== undefined;
    const hasShape = cell.shape !== undefined;
    if (hasNumber === hasShape) fail('katakchada aynan bitta qiymat kerak');
    if (
      hasNumber &&
      (!Number.isInteger(cell.number) || cell.number < 0 || cell.number > 20)
    ) {
      fail(`raqamli javob 0..20 emas: ${cell.number}`);
    }
  }
  const correct = q.answers[q.correctIndex].number;
  if (correct !== undefined && correct > 5) {
    for (const cell of q.answers) {
      if (cell.number !== undefined && cell.number > 2 * correct) {
        fail(`distraktor 2x dan katta: ${cell.number} (correct ${correct})`);
      }
    }
  }
  if (q.type === 'subtraction' && q.data.a - q.data.b < 1) {
    fail(`ayirish natijasi 1 dan kichik: ${q.data.a} - ${q.data.b}`);
  }
  if (q.visual?.count !== undefined && q.visual.count > 12) {
    fail(`vizual soni 12 dan katta: ${q.visual.count}`);
  }
}

/**
 * Savolning MAZMUNIY o'zligi — bola ekranda ko'radigan topshiriq.
 *
 * Diqqat: `data` savolni har doim to'liq aniqlamaydi —
 *   - `counting` da son `visual.count` da (`data` faqat hayvonni saqlaydi);
 *   - `comparison` da to'rt son `answers` da (`data` faqat rejimni saqlaydi).
 * Shu sababli imzo shu joylardan ham o'qiydi, aks holda haqiqatan har xil
 * savollar «takror» deb noto'g'ri rad etilardi.
 */
function questionSignature(q) {
  const d = q.data;
  switch (q.type) {
    case 'counting':
      return `counting|${d.animal}|${q.visual?.count}`;
    case 'addition':
    case 'subtraction':
      return `${q.type}|${d.a}|${d.b}|${d.missing}`;
    case 'multiplication':
      return `multiplication|${d.a}|${d.b}`;
    case 'sequence':
      return `sequence|${d.terms.join(',')}`;
    case 'shapes':
      return `shapes|${d.target}`;
    case 'comparison':
      return `comparison|${d.mode}|${q.answers
        .map((cell) => cell.number)
        .slice()
        .sort((x, y) => x - y)
        .join(',')}`;
    default:
      throw new Error(`imzo uchun noma'lum savol turi: ${q.type}`);
  }
}

/** Daraja ichidagi takror savollar soni (0 — hammasi har xil). */
function duplicateCount(questions) {
  const seen = new Set();
  let dups = 0;
  for (const q of questions) {
    const sig = questionSignature(q);
    if (seen.has(sig)) dups += 1;
    else seen.add(sig);
  }
  return dups;
}

// Takrorsiz to'plam topish uchun urug'ni qayta surish chegarasi. 6-2 eng qattiq
// holat (3× jadval: b ∈ 2..6 — aynan 5 imkoniyat, 5 savol), shuning uchun zaxira
// keng olingan.
const MAX_DEDUP_ATTEMPTS = 500;

function buildLevel({
  id,
  timerSeconds = 0,
  shuffleAnswers = true,
  allowedRepeats = 0,
  build,
}) {
  const [chapterStr, indexStr] = id.split('-');
  const qid = (n) => `${id}-q${n}`;
  let questions;
  let attempt = 0;
  for (; attempt < MAX_DEDUP_ATTEMPTS; attempt += 1) {
    // attempt 0 — tarixiy urug': takrorsiz darajalar BAYT-BAYT o'zgarmaydi.
    const rng = mulberry32(fnv1a(attempt === 0 ? id : `${id}#${attempt}`));
    questions = build(rng, qid);
    if (questions.length !== QUESTIONS_PER_LEVEL) {
      throw new Error(`daraja ${id}: ${QUESTIONS_PER_LEVEL} ta savol emas`);
    }
    if (duplicateCount(questions) <= allowedRepeats) break;
  }
  if (attempt >= MAX_DEDUP_ATTEMPTS) {
    throw new Error(
      `daraja ${id}: ${MAX_DEDUP_ATTEMPTS} urinishda ham takror savol ` +
        `yo'qolmadi (ruxsat etilgan: ${allowedRepeats})`,
    );
  }
  questions.forEach(validateQuestion);
  return {
    id,
    chapter: Number(chapterStr),
    index: Number(indexStr),
    timerEnabled: timerSeconds > 0,
    timerSeconds,
    shuffleAnswers,
    questions,
  };
}

// ---------- Yozish ----------

const levels = LEVEL_DEFS.map(buildLevel);
mkdirSync(OUT_DIR, { recursive: true });
const chapterIds = [...new Set(levels.map((l) => l.chapter))].sort(
  (a, b) => a - b,
);
for (const chapterId of chapterIds) {
  const chapterLevels = levels.filter((level) => level.chapter === chapterId);
  const root = {
    schemaVersion: SCHEMA_VERSION,
    chapter: { id: chapterId, levels: chapterLevels },
  };
  writeFileSync(
    join(OUT_DIR, `ch${chapterId}.json`),
    `${JSON.stringify(root, null, 2)}\n`,
  );
  const total = chapterLevels.reduce((s, l) => s + l.questions.length, 0);
  console.log(`ch${chapterId}.json: ${chapterLevels.length} daraja, ${total} savol`);
}
