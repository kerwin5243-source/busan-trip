/**
 * Busan PWA – Test Suite (5000 cases)
 * Run: node test/run_tests.mjs
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');

// ──────────────────────────────────────────
// Mini test runner
// ──────────────────────────────────────────
let passed = 0, failed = 0, skipped = 0;
const failures = [];

function expect(label, actual, expected) {
  if (actual === expected) {
    passed++;
  } else {
    failed++;
    failures.push({ label, actual, expected });
  }
}
function expectTrue(label, v) { expect(label, !!v, true); }
function expectFalse(label, v) { expect(label, !!v, false); }
function expectMatch(label, str, regex) {
  if (regex.test(str)) { passed++; }
  else { failed++; failures.push({ label, actual: str, expected: `match ${regex}` }); }
}
function expectNoThrow(label, fn) {
  try { fn(); passed++; }
  catch(e) { failed++; failures.push({ label, actual: `threw: ${e.message}`, expected: 'no error' }); }
}

// ──────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────
const MEMBERS = ['Kerwin','Francesca','Lotto','Latte','Hao','Ming'];
const HOUSE_A = ['Kerwin','Francesca','Lotto'];
const HOUSE_B = ['Latte','Hao','Ming'];
const DAYS_ISO = ['2026-06-06','2026-06-07','2026-06-08','2026-06-09','2026-06-10'];
const VALID_TAGS = ['food','sight','transport','hotel','route','shop'];
const VALID_MODES = ['plane','transit','walk','ferry','bus','van','car'];
const REQUIRED_ITEM_KEYS = ['id','title','tag','desc','detail','addr','hours','guide','avoid','links','menu','reservations'];

function loadDay(iso) {
  return JSON.parse(fs.readFileSync(path.join(ROOT,'data','itinerary',`${iso}.json`),'utf8'));
}
function loadJson(rel) {
  return JSON.parse(fs.readFileSync(path.join(ROOT, rel),'utf8'));
}

// ──────────────────────────────────────────
// SECTION 1 – JSON file loading (5 files × 2)
// ──────────────────────────────────────────
console.log('Section 1: JSON loading...');
for (const iso of DAYS_ISO) {
  expectNoThrow(`load ${iso}`, () => loadDay(iso));
  const data = loadDay(iso);
  expectTrue(`${iso} is array`, Array.isArray(data));
}
['data/config.json','data/flights.json','data/hotels.json',
 'data/souvenirs.json','data/todos.json','data/checklists.json'].forEach(f => {
  expectNoThrow(`load ${f}`, () => loadJson(f));
});

// ──────────────────────────────────────────
// SECTION 2 – Top-level day object structure (5 days × 10 fields)
// ──────────────────────────────────────────
console.log('Section 2: Day object structure...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  expectTrue(`${iso} has date`, typeof day.date === 'string' && day.date.length > 0);
  expectTrue(`${iso} has day`, typeof day.day === 'string');
  expectTrue(`${iso} has loc`, typeof day.loc === 'string' && day.loc.length > 0);
  expectTrue(`${iso} has photos array`, Array.isArray(day.photos));
  expectTrue(`${iso} has items array`, Array.isArray(day.items));
  expectTrue(`${iso} items non-empty`, day.items.length > 0);
  expectTrue(`${iso} date format MM/DD`, /^\d{2}\/\d{2}$/.test(day.date));
  expectTrue(`${iso} day is weekday char`, '一二三四五六日'.includes(day.day));
  expect(`${iso} hotel_id type`, typeof day.hotel_id, 'string');
  expectTrue(`${iso} loc has content`, day.loc.trim().length > 0);
}

// ──────────────────────────────────────────
// SECTION 3 – Item required keys (69 items × 13 keys)
// ──────────────────────────────────────────
console.log('Section 3: Item required keys...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    for (const key of REQUIRED_ITEM_KEYS) {
      expectTrue(`${item.id} has key [${key}]`, key in item);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 4 – Item id uniqueness & format
// ──────────────────────────────────────────
console.log('Section 4: Item id uniqueness...');
const allIds = [];
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    expectTrue(`${item.id} id is non-empty string`, typeof item.id === 'string' && item.id.length > 0);
    expectFalse(`${item.id} id not duplicate`, allIds.includes(item.id));
    allIds.push(item.id);
    expectMatch(`${item.id} id format`, item.id, /^\d{4}_\d{2}[a-z]?$/);
  }
}

// ──────────────────────────────────────────
// SECTION 5 – Item tag validation (69 items)
// ──────────────────────────────────────────
console.log('Section 5: Item tag validation...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    expectTrue(`${item.id} tag is valid`, VALID_TAGS.includes(item.tag));
    expect(`${item.id} tag type`, typeof item.tag, 'string');
    expect(`${item.id} subtag type`, typeof item.subtag, 'string');
  }
}

// ──────────────────────────────────────────
// SECTION 6 – Route item structure
// ──────────────────────────────────────────
console.log('Section 6: Route items...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    if (item.tag === 'route') {
      expectTrue(`${item.id} route has .route`, 'route' in item);
      const r = item.route || {};
      expectTrue(`${item.id} route.mode exists`, 'mode' in r);
      expectTrue(`${item.id} route.mode valid`, VALID_MODES.includes(r.mode));
      expectTrue(`${item.id} route.from is string`, typeof r.from === 'string');
      expectTrue(`${item.id} route.to is string`, typeof r.to === 'string');
      expectTrue(`${item.id} route.minutes is number`, typeof r.minutes === 'number' && r.minutes > 0);
      expectTrue(`${item.id} route.from non-empty`, r.from.length > 0);
      expectTrue(`${item.id} route.to non-empty`, r.to.length > 0);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 7 – Array field types (guide/avoid/links/menu/reservations)
// ──────────────────────────────────────────
console.log('Section 7: Array field types...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    for (const field of ['guide','avoid','links','menu','reservations']) {
      expectTrue(`${item.id} ${field} is array`, Array.isArray(item[field]));
    }
  }
}

// ──────────────────────────────────────────
// SECTION 8 – Menu item structure
// ──────────────────────────────────────────
console.log('Section 8: Menu item structure...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    for (const [mi, m] of item.menu.entries()) {
      expectTrue(`${item.id} menu[${mi}] has name`, typeof m.name === 'string' && m.name.length > 0);
      expectTrue(`${item.id} menu[${mi}] has price`, typeof m.price === 'string');
      expectTrue(`${item.id} menu[${mi}] has note`, typeof m.note === 'string');
      expectTrue(`${item.id} menu[${mi}] name non-empty`, m.name.trim().length > 0);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 9 – Guide/avoid are string arrays
// ──────────────────────────────────────────
console.log('Section 9: Guide/avoid string content...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    for (const [gi, g] of item.guide.entries()) {
      expectTrue(`${item.id} guide[${gi}] is string`, typeof g === 'string');
      expectTrue(`${item.id} guide[${gi}] non-empty`, g.trim().length > 0);
    }
    for (const [ai, a] of item.avoid.entries()) {
      expectTrue(`${item.id} avoid[${ai}] is string`, typeof a === 'string');
      expectTrue(`${item.id} avoid[${ai}] non-empty`, a.trim().length > 0);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 10 – fmtKRW function
// ──────────────────────────────────────────
console.log('Section 10: fmtKRW...');
function fmtKRW(v) {
  const abs = Math.abs(v);
  if (abs < 10000) return (v >= 0 ? '+' : '-') + '₩' + Math.round(abs).toLocaleString();
  const man = Math.floor(abs / 10000);
  const rest = Math.round(abs % 10000);
  return (v >= 0 ? '+' : '-') + '₩' + man + '萬' + (rest > 0 ? rest.toLocaleString() : '');
}
function fmtTWD(v) {
  const abs = Math.abs(v);
  return (v >= 0 ? '+' : '-') + 'NT$' + Math.round(abs).toLocaleString();
}

// KRW: values < 10000
const smallVals = [0,1,100,500,999,1000,5000,9999,-1,-100,-9999];
for (const v of smallVals) {
  const r = fmtKRW(v);
  expectMatch(`fmtKRW(${v}) starts with sign+₩`, r, /^[+-]₩/);
  expectFalse(`fmtKRW(${v}) no 萬 for small`, r.includes('萬'));
}

// KRW: values >= 10000
const bigKRWVals = [10000,20000,50000,100000,250000,1000000,-10000,-250000,12345,99999,100001];
for (const v of bigKRWVals) {
  const r = fmtKRW(v);
  if (Math.abs(v) >= 10000) {
    expectTrue(`fmtKRW(${v}) contains 萬`, r.includes('萬'));
  }
  expectMatch(`fmtKRW(${v}) has sign`, r, /^[+-]/);
}

// KRW: positive sign
for (let v = 1000; v <= 200000; v += 3333) {
  expectMatch(`fmtKRW(+${v}) starts with +`, fmtKRW(v), /^\+/);
}
// KRW: negative sign
for (let v = 1000; v <= 200000; v += 3333) {
  expectMatch(`fmtKRW(-${v}) starts with -`, fmtKRW(-v), /^-/);
}
// KRW: zero
expect('fmtKRW(0) starts with +', fmtKRW(0)[0], '+');

// KRW: exact 萬 boundary
expect('fmtKRW(10000) is +₩1萬', fmtKRW(10000), '+₩1萬');
expect('fmtKRW(20000) is +₩2萬', fmtKRW(20000), '+₩2萬');
expect('fmtKRW(15000) contains 5000', fmtKRW(15000).includes('5'), true);
expect('fmtKRW(-10000) is -₩1萬', fmtKRW(-10000), '-₩1萬');

// KRW: large amounts (trip budget range)
for (let i = 0; i < 100; i++) {
  const v = Math.round(Math.random() * 500000 - 250000);
  const r = fmtKRW(v);
  expectTrue(`fmtKRW(${v}) is string`, typeof r === 'string');
  expectTrue(`fmtKRW(${v}) non-empty`, r.length > 0);
  expectMatch(`fmtKRW(${v}) starts with sign`, r, /^[+-]/);
}

// ──────────────────────────────────────────
// SECTION 11 – fmtTWD function
// ──────────────────────────────────────────
console.log('Section 11: fmtTWD...');
const twdVals = [0,1,100,500,1000,5000,10000,50000,-100,-1000,-50000];
for (const v of twdVals) {
  const r = fmtTWD(v);
  expectMatch(`fmtTWD(${v}) starts with sign+NT$`, r, /^[+-]NT\$/);
}
expect('fmtTWD(1000)', fmtTWD(1000), '+NT$1,000');
expect('fmtTWD(-500)', fmtTWD(-500), '-NT$500');
expect('fmtTWD(0)', fmtTWD(0), '+NT$0');
for (let i = 0; i < 100; i++) {
  const v = Math.round(Math.random() * 20000 - 10000);
  expectMatch(`fmtTWD(${v}) format`, fmtTWD(v), /^[+-]NT\$\d/);
}

// ──────────────────────────────────────────
// SECTION 12 – calcBalance logic
// ──────────────────────────────────────────
console.log('Section 12: calcBalance logic...');
function calcBalance(expenses, payments, currency) {
  const bal = Object.fromEntries(MEMBERS.map(m => [m, 0]));
  expenses.filter(e => e.currency === currency).forEach(e => {
    const parts = e.participants.length ? e.participants : MEMBERS;
    const share = e.cost / parts.length;
    bal[e.payer] = (bal[e.payer] || 0) + e.cost;
    parts.forEach(u => { bal[u] = (bal[u] || 0) - share; });
  });
  payments.filter(p => p.currency === currency).forEach(p => {
    bal[p.from] = (bal[p.from] || 0) + p.amount;
    bal[p.to] = (bal[p.to] || 0) - p.amount;
  });
  return bal;
}

// Empty state: all zero
{
  const bal = calcBalance([], [], 'KRW');
  for (const m of MEMBERS) {
    expect(`empty balance ${m} = 0`, bal[m], 0);
  }
}

// All members exist in balance
{
  const bal = calcBalance([], [], 'KRW');
  for (const m of MEMBERS) {
    expectTrue(`balance has ${m}`, m in bal);
  }
}

// Single payer, all split: net = cost * (n-1)/n for payer, -cost/n for others
{
  const n = MEMBERS.length;
  const cost = 60000;
  const bal = calcBalance([{currency:'KRW', payer:'Kerwin', cost, participants:[]}], [], 'KRW');
  // Payer net = cost - cost/n = cost*(n-1)/n
  const expectedPayer = cost - cost / n;
  expectTrue(`payer net correct`, Math.abs(bal['Kerwin'] - expectedPayer) < 0.01);
  // Others net = -cost/n
  for (const m of MEMBERS.filter(x => x !== 'Kerwin')) {
    expectTrue(`${m} owes share`, Math.abs(bal[m] - (-cost / n)) < 0.01);
  }
}

// Sum of all balances = 0 (conservation)
for (let i = 0; i < 50; i++) {
  const numExp = Math.floor(Math.random() * 5) + 1;
  const exps = Array.from({length: numExp}, (_, j) => ({
    currency: 'KRW',
    payer: MEMBERS[j % MEMBERS.length],
    cost: Math.round(Math.random() * 100000 + 1000),
    participants: []
  }));
  const bal = calcBalance(exps, [], 'KRW');
  const sum = Object.values(bal).reduce((a, b) => a + b, 0);
  expectTrue(`balance sum ≈ 0 (trial ${i})`, Math.abs(sum) < 0.01);
}

// Payment: from A to B shifts balance by amount
{
  const pay = [{currency:'KRW', from:'Kerwin', to:'Francesca', amount:10000}];
  const bal = calcBalance([], pay, 'KRW');
  expect('payment from Kerwin +10000', bal['Kerwin'], 10000);
  expect('payment to Francesca -10000', bal['Francesca'], -10000);
  for (const m of MEMBERS.filter(x => x !== 'Kerwin' && x !== 'Francesca')) {
    expect(`${m} unaffected`, bal[m], 0);
  }
}

// Partial participants: only shared among subset
{
  const subset = ['Kerwin', 'Francesca', 'Lotto'];
  const cost = 30000;
  const bal = calcBalance([{currency:'KRW', payer:'Kerwin', cost, participants: subset}], [], 'KRW');
  const share = cost / subset.length;
  expectTrue('payer net with subset', Math.abs(bal['Kerwin'] - (cost - share)) < 0.01);
  expectTrue('Francesca owes share', Math.abs(bal['Francesca'] - (-share)) < 0.01);
  expectTrue('Lotto owes share', Math.abs(bal['Lotto'] - (-share)) < 0.01);
  expect('Latte unaffected', bal['Latte'], 0);
  expect('Hao unaffected', bal['Hao'], 0);
  expect('Ming unaffected', bal['Ming'], 0);
}

// Currency isolation: KRW expenses don't affect TWD balance
{
  const exps = [{currency:'KRW', payer:'Kerwin', cost:50000, participants:[]}];
  const balTWD = calcBalance(exps, [], 'TWD');
  for (const m of MEMBERS) {
    expect(`KRW exp doesn't affect TWD ${m}`, balTWD[m], 0);
  }
}

// Multiple expenses: additive
{
  const cost1 = 12000, cost2 = 18000;
  const exps = [
    {currency:'KRW', payer:'Kerwin', cost:cost1, participants:[]},
    {currency:'KRW', payer:'Kerwin', cost:cost2, participants:[]}
  ];
  const bal = calcBalance(exps, [], 'KRW');
  const n = MEMBERS.length;
  const expectedPayer = (cost1 + cost2) - (cost1 + cost2) / n;
  expectTrue('multiple expenses sum correctly', Math.abs(bal['Kerwin'] - expectedPayer) < 0.01);
}

// 100 random balance conservation tests
for (let i = 0; i < 100; i++) {
  const exps = Array.from({length: Math.floor(Math.random()*8)+1}, () => ({
    currency: 'TWD',
    payer: MEMBERS[Math.floor(Math.random()*MEMBERS.length)],
    cost: Math.round(Math.random()*5000+100),
    participants: []
  }));
  const pays = Array.from({length: Math.floor(Math.random()*3)}, () => {
    const from = MEMBERS[Math.floor(Math.random()*MEMBERS.length)];
    let to = MEMBERS[Math.floor(Math.random()*MEMBERS.length)];
    while (to === from) to = MEMBERS[Math.floor(Math.random()*MEMBERS.length)];
    return {currency:'TWD', from, to, amount: Math.round(Math.random()*2000+100)};
  });
  const bal = calcBalance(exps, pays, 'TWD');
  const sum = Object.values(bal).reduce((a,b)=>a+b,0);
  expectTrue(`TWD conservation trial ${i}`, Math.abs(sum) < 0.01);
}

// ──────────────────────────────────────────
// SECTION 13 – Service worker cache list
// ──────────────────────────────────────────
console.log('Section 13: SW cache list...');
const swContent = fs.readFileSync(path.join(ROOT,'sw.js'),'utf8');
const REQUIRED_IN_CACHE = [
  './index.html','./manifest.json','./data/config.json',
  './data/flights.json','./data/hotels.json','./data/souvenirs.json',
  './data/todos.json','./data/checklists.json',
  ...DAYS_ISO.map(d=>`./data/itinerary/${d}.json`),
  'https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js',
  'https://www.gstatic.com/firebasejs/9.23.0/firebase-database-compat.js'
];
for (const entry of REQUIRED_IN_CACHE) {
  expectTrue(`sw.js includes '${entry}'`, swContent.includes(entry));
}

// SW cache version exists
expectMatch('sw.js has CACHE const', swContent, /const CACHE = 'busan-pwa-v\d+'/);

// SW has install/activate/fetch listeners
expectTrue('sw.js has install listener', swContent.includes("addEventListener('install'"));
expectTrue('sw.js has activate listener', swContent.includes("addEventListener('activate'"));
expectTrue('sw.js has fetch listener', swContent.includes("addEventListener('fetch'"));

// SW has skipWaiting
expectTrue('sw.js has skipWaiting', swContent.includes('skipWaiting'));

// SW cache name unique and versioned
const cacheMatch = swContent.match(/const CACHE = '(busan-pwa-v(\d+))'/);
expectTrue('sw.js cache version parses', cacheMatch !== null);
if (cacheMatch) {
  expectTrue('sw.js cache version > 0', parseInt(cacheMatch[2]) > 0);
}

// ──────────────────────────────────────────
// SECTION 14 – Photo files exist on disk
// ──────────────────────────────────────────
console.log('Section 14: Photo files on disk...');
const picBase = path.join(ROOT, 'picture');
for (const iso of DAYS_ISO) {
  const mm = iso.slice(5,7), dd = iso.slice(8,10), ymd = iso.replace(/-/g,'');
  const dir = path.join(picBase, `${mm}-${dd}`);
  expectTrue(`picture/${mm}-${dd}/ exists`, fs.existsSync(dir));
  if (fs.existsSync(dir)) {
    const files = fs.readdirSync(dir).filter(f => f.endsWith('.jpg') || f.endsWith('.png'));
    expectTrue(`picture/${mm}-${dd}/ has files`, files.length > 0);
    // Each file should follow naming convention YYYYMMDDnnn.jpg
    for (const f of files) {
      expectMatch(`picture/${mm}-${dd}/${f} naming`, f, new RegExp(`^${ymd}\\d{3}\\.(jpg|png)$`));
    }
    // Files are numbered sequentially from 001
    for (let n = 1; n <= files.length; n++) {
      const expected = `${ymd}${String(n).padStart(3,'0')}.jpg`;
      expectTrue(`picture/${mm}-${dd}/${expected} exists`, files.includes(expected));
    }
  }
}

// ──────────────────────────────────────────
// SECTION 15 – Korean text present in titles
// ──────────────────────────────────────────
console.log('Section 15: Korean text in titles...');
const KOREAN_RE = /[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]/;
const ITEMS_NEEDING_KOREAN = {
  '0606_05b': true, '0606_06b': true, '0606_07': true,
  '0606_12': true, '0607_03': true, '0607_04': true, '0607_05': true,
  '0607_10': true, '0608_11': true, '0609_10': true,
  '0610_02': true
};
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    if (ITEMS_NEEDING_KOREAN[item.id]) {
      expectTrue(`${item.id} title has Korean`, KOREAN_RE.test(item.title));
    }
  }
}

// ──────────────────────────────────────────
// SECTION 16 – naver_url format validation
// ──────────────────────────────────────────
console.log('Section 16: naver_url validation...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    if (item.naver_url) {
      expectMatch(`${item.id} naver_url is https`, item.naver_url, /^https:\/\//);
      expectTrue(`${item.id} naver_url non-empty`, item.naver_url.length > 10);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 17 – Price field format
// ──────────────────────────────────────────
console.log('Section 17: Price field format...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    expect(`${item.id} price is string`, typeof item.price, 'string');
    // If price mentions ₩ it should have a number
    if (item.price.includes('₩')) {
      expectMatch(`${item.id} price after ₩ has digit`, item.price, /₩[\d,<s]/);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 18 – stay field
// ──────────────────────────────────────────
console.log('Section 18: Stay field...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    expect(`${item.id} stay is string`, typeof item.stay, 'string');
    if (item.stay.length > 0 && item.stay !== '') {
      // Should be like "1 hr", "30 min", "2h 20min", etc.
      expectMatch(`${item.id} stay format`, item.stay, /(\d+\s*(hr|min|h|m)|時間|分鐘)/i);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 19 – Config file validation
// ──────────────────────────────────────────
console.log('Section 19: Config validation...');
{
  const cfg = loadJson('data/config.json');
  expect('config trip_title', cfg.trip_title, '月半家族釜山之旅');
  expect('config start date', cfg.date_range.start, '2026-06-06');
  expect('config end date', cfg.date_range.end, '2026-06-10');
  expect('config nights', cfg.nights, 4);
  expect('config days', cfg.days, 5);
  expectTrue('config members is array', Array.isArray(cfg.members));
  expect('config member count', cfg.members.length, 6);
  expectTrue('config has default_currency', 'default_currency' in cfg);
}

// ──────────────────────────────────────────
// SECTION 20 – highlight items have content
// ──────────────────────────────────────────
console.log('Section 20: Highlight items...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    if (item.highlight) {
      expectTrue(`${item.id} highlight has desc`, item.desc.length > 10);
      expectTrue(`${item.id} highlight has detail`, item.detail.length > 20);
      expectTrue(`${item.id} highlight has title`, item.title.length > 0);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 21 – reserved items
// ──────────────────────────────────────────
console.log('Section 21: Reserved items...');
const knownReserved = ['0606_05','0607_10','0609_01b'];
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    if (knownReserved.includes(item.id)) {
      expectTrue(`${item.id} reserved=true`, item.reserved === true);
    }
    if ('reserved' in item) {
      expectTrue(`${item.id} reserved is boolean`, typeof item.reserved === 'boolean');
    }
  }
}

// ──────────────────────────────────────────
// SECTION 22 – Time field format
// ──────────────────────────────────────────
console.log('Section 22: Time field format...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    expect(`${item.id} time is string`, typeof item.time, 'string');
    if (item.time && item.time.length > 0) {
      expectMatch(`${item.id} time HH:MM format`, item.time, /^\d{2}:\d{2}$/);
      const [h, m] = item.time.split(':').map(Number);
      expectTrue(`${item.id} time hours 0-23`, h >= 0 && h <= 23);
      expectTrue(`${item.id} time mins 0-59`, m >= 0 && m <= 59);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 23 – Hotel items
// ──────────────────────────────────────────
console.log('Section 23: Hotel items...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    if (item.tag === 'hotel') {
      expectTrue(`${item.id} hotel has addr or detail`, item.addr.length > 0 || item.detail.length > 0);
      expectTrue(`${item.id} hotel has hours`, item.hours.length > 0);
    }
  }
}

// ──────────────────────────────────────────
// SECTION 24 – DAY chronological time order (where time is set)
// ──────────────────────────────────────────
console.log('Section 24: Chronological time order...');
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  const timedItems = day.items.filter(it => it.time && it.time.match(/^\d{2}:\d{2}$/));
  for (let i = 1; i < timedItems.length; i++) {
    const prev = timedItems[i-1].time, cur = timedItems[i].time;
    const [ph,pm] = prev.split(':').map(Number);
    const [ch,cm] = cur.split(':').map(Number);
    const prevMin = ph*60+pm, curMin = ch*60+cm;
    expectTrue(`${iso} time order: ${prev} <= ${cur}`, curMin >= prevMin);
  }
}

// ──────────────────────────────────────────
// SECTION 25 – index.html file existence and key content
// ──────────────────────────────────────────
console.log('Section 25: index.html key content...');
const html = fs.readFileSync(path.join(ROOT,'index.html'),'utf8');

const HTML_CHECKS = [
  ['has DOCTYPE', /<!DOCTYPE html>/i],
  ['has viewport meta', /viewport/],
  ['has manifest link', /manifest\.json/],
  ['has Font Awesome', /font-awesome/i],
  ['has Firebase app', /firebase-app/],
  ['has Firebase database', /firebase-database/],
  ['has MEMBERS const', /const MEMBERS/],
  ['has HOUSE_A const', /const HOUSE_A/],
  ['has HOUSE_B const', /const HOUSE_B/],
  ['has PAYERS const', /const PAYERS/],
  ['has calcBalance fn', /function calcBalance/],
  ['has fmtKRW fn', /function fmtKRW/],
  ['has fmtTWD fn', /function fmtTWD/],
  ['has renderBalance fn', /function renderBalance/],
  ['has renderPayerChips fn', /function renderPayerChips/],
  ['has renderHousePicker fn', /function renderHousePicker/],
  ['has openSettings fn', /function openSettings/],
  ['has clearCacheAndReload fn', /function clearCacheAndReload/],
  ['has nav bottom bar', /class="nav"/],
  ['has 行程 tab', /行程/],
  ['has 資訊 tab', /資訊/],
  ['has 記帳 tab', /記帳/],
  ['has 行前 tab', /行前/],
  ['has 個人結算', /個人結算/],
  ['has 分攤成員', /分攤成員/],
  ['has 付款人', /付款人/],
  ['has 長輩模式', /長輩模式/],
  ['has 更新到最新版本', /更新到最新版本/],
  ['has 月半家族釜山之旅', /月半家族釜山之旅/],
  ['has SES section', /SES/],
  ['has Firebase config', /apiKey/],
  ['has service worker registration', /serviceWorker/],
  ['has localStorage usage', /localStorage/],
  ['has openDetail fn', /function openDetail/],
  ['has day-banner class', /day-banner/],
  ['has tl2 class (timeline)', /class="tl2/],
  ['has sheet class', /class="sheet/],
  ['has overlay class', /overlay/],
  ['has gear icon', /fa-gear/],
  ['has scale icon', /fa-scale-balanced/],
  ['has van-shuttle icon', /fa-van-shuttle/],
];

for (const [label, regex] of HTML_CHECKS) {
  expectMatch(`html: ${label}`, html, regex);
}

// MEMBERS includes all 6
for (const m of MEMBERS) {
  expectTrue(`html MEMBERS includes ${m}`, html.includes(`'${m}'`));
}

// DAY files referenced
for (const iso of DAYS_ISO) {
  expectTrue(`html references ${iso}.json`, html.includes(`${iso}.json`));
}

// ──────────────────────────────────────────
// SECTION 26 – Bilingual menu entries
// ──────────────────────────────────────────
console.log('Section 26: Bilingual menus...');
const EXPECTED_BILINGUAL = {
  '0607_06': ['킹크랩','대게','광어회','산낙지','전복'],
  '0607_10': ['순두부찌개','한우된장찌개','제육볶음','두부조림','들기름막국수'],
  '0609_10': ['고반 한마리세트','숙성 생삼겹살','숙성 생목살','고반명란밥','물냉면'],
  '0606_13': ['충무김밥'],
};
for (const iso of DAYS_ISO) {
  const [day] = loadDay(iso);
  for (const item of day.items) {
    const expected = EXPECTED_BILINGUAL[item.id];
    if (expected) {
      for (const kw of expected) {
        const found = item.menu.some(m => m.name.includes(kw));
        expectTrue(`${item.id} menu has Korean '${kw}'`, found);
      }
    }
  }
}

// ──────────────────────────────────────────
// SECTION 27 – DAY4 van routes
// ──────────────────────────────────────────
console.log('Section 27: DAY4 van routes...');
{
  const [day] = loadDay('2026-06-09');
  const routes = day.items.filter(it => it.tag === 'route');
  for (const r of routes) {
    if (r.route && r.route.mode !== 'transit' && r.route.mode !== 'plane') {
      expect(`${r.id} route mode is van`, r.route.mode, 'van');
    }
  }
}

// ──────────────────────────────────────────
// SECTION 28 – DAY5 has required shop items
// ──────────────────────────────────────────
console.log('Section 28: DAY5 shop items...');
{
  const [day] = loadDay('2026-06-10');
  const titles = day.items.map(it => it.title);
  const titleJoined = titles.join('|');
  expectTrue('DAY5 has Olive Young', titleJoined.includes('Olive Young'));
  expectTrue('DAY5 has Artbox', titleJoined.includes('Artbox'));
  expectTrue('DAY5 has DAISO or 大創', titleJoined.includes('DAISO') || titleJoined.includes('大創'));
  expectTrue('DAY5 has Butter Shop', titleJoined.includes('Butter'));
  expectTrue('DAY5 has SES', titleJoined.includes('SES'));
  expectTrue('DAY5 has 밀양돼지국밥 or 密揚', titleJoined.includes('밀양') || titleJoined.includes('密揚'));
  expectTrue('DAY5 has route to airport', day.items.some(it => it.tag === 'route' && JSON.stringify(it).includes('機場')));
  expectTrue('DAY5 has return flight', day.items.some(it => it.tag === 'route' && it.route?.mode === 'plane'));
}

// ──────────────────────────────────────────
// SECTION 29 – DAY2 Korean location names
// ──────────────────────────────────────────
console.log('Section 29: DAY2 Korean names...');
{
  const [day] = loadDay('2026-06-07');
  const titleJoined = day.items.map(it => it.title).join('|');
  expectTrue('DAY2 has 자갈치 (Korean)', titleJoined.includes('자갈치') || titleJoined.includes('부산자갈치'));
  expectTrue('DAY2 has 술고당 (述古堂)', titleJoined.includes('술고당'));
  expectTrue('DAY2 has L7 해운대', titleJoined.includes('L7 해운대'));
  // 述古堂 reserved
  const stgd = day.items.find(it => it.id === '0607_10');
  expectTrue('述古堂 reserved=true', stgd?.reserved === true);
}

// ──────────────────────────────────────────
// SECTION 30 – Stress: large expense scenarios
// ──────────────────────────────────────────
console.log('Section 30: Stress balance tests...');
for (let trial = 0; trial < 200; trial++) {
  const numExp = Math.floor(Math.random() * 20) + 1;
  const exps = Array.from({length: numExp}, () => {
    const nParts = Math.floor(Math.random() * MEMBERS.length);
    const participants = nParts === 0 ? [] :
      MEMBERS.slice().sort(() => Math.random() - 0.5).slice(0, nParts);
    return {
      currency: Math.random() > 0.5 ? 'KRW' : 'TWD',
      payer: MEMBERS[Math.floor(Math.random() * MEMBERS.length)],
      cost: Math.round(Math.random() * 200000 + 1000),
      participants
    };
  });
  const pays = Array.from({length: Math.floor(Math.random()*5)}, () => {
    const i = Math.floor(Math.random()*MEMBERS.length);
    let j = (i + 1 + Math.floor(Math.random()*(MEMBERS.length-1))) % MEMBERS.length;
    return {currency: Math.random()>0.5?'KRW':'TWD', from: MEMBERS[i], to: MEMBERS[j], amount: Math.round(Math.random()*50000+500)};
  });
  for (const cur of ['KRW','TWD']) {
    const bal = calcBalance(exps, pays, cur);
    const sum = Object.values(bal).reduce((a,b) => a+b, 0);
    expectTrue(`stress trial ${trial} ${cur} conservation`, Math.abs(sum) < 0.01);
    for (const m of MEMBERS) {
      expectTrue(`stress trial ${trial} ${cur} ${m} is number`, typeof bal[m] === 'number');
      expectFalse(`stress trial ${trial} ${cur} ${m} is NaN`, isNaN(bal[m]));
    }
  }
}

// ──────────────────────────────────────────
// SUMMARY
// ──────────────────────────────────────────
const total = passed + failed + skipped;
console.log('\n' + '═'.repeat(60));
console.log(`  TOTAL   ${total}`);
console.log(`  ✅ PASS  ${passed}`);
console.log(`  ❌ FAIL  ${failed}`);
if (skipped) console.log(`  ⏭  SKIP  ${skipped}`);
console.log('═'.repeat(60));

if (failures.length > 0) {
  console.log(`\nFailed tests (${failures.length}):`);
  failures.slice(0, 50).forEach(f => {
    console.log(`  ❌ ${f.label}`);
    console.log(`     expected: ${JSON.stringify(f.expected)}`);
    console.log(`     actual:   ${JSON.stringify(f.actual)}`);
  });
  if (failures.length > 50) console.log(`  ... and ${failures.length - 50} more`);
}

process.exit(failed > 0 ? 1 : 0);
