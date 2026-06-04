const CACHE = 'busan-pwa-v36';
const PRE = [
  './', './index.html', './manifest.json',
  './data/config.json', './data/flights.json', './data/hotels.json',
  './data/souvenirs.json', './data/todos.json', './data/checklists.json',
  './data/itinerary/2026-06-06.json', './data/itinerary/2026-06-07.json',
  './data/itinerary/2026-06-08.json', './data/itinerary/2026-06-09.json',
  './data/itinerary/2026-06-10.json',
  './picture/busan_souvenirs/sou_001.png','./picture/busan_souvenirs/sou_002.jpg',
  './picture/busan_souvenirs/sou_002.png','./picture/busan_souvenirs/sou_003.jpg',
  './picture/busan_souvenirs/sou_004.jpg','./picture/busan_souvenirs/sou_005.png',
  './picture/busan_souvenirs/sou_006.png','./picture/busan_souvenirs/sou_007.jpg',
  './picture/busan_souvenirs/sou_008.jpg','./picture/busan_souvenirs/sou_009.png',
  './picture/busan_souvenirs/sou_010.png','./picture/busan_souvenirs/sou_011.png',
  './picture/busan_souvenirs/sou_012.png','./picture/busan_souvenirs/sou_013.png',
  './picture/busan_souvenirs/sou_014.png','./picture/busan_souvenirs/sou_015.png',
  './picture/busan_souvenirs/sou_016.jpg','./picture/busan_souvenirs/sou_017.jpg',
  './picture/busan_souvenirs/sou_018.png','./picture/busan_souvenirs/sou_019.png',
  './picture/busan_souvenirs/sou_020.png','./picture/busan_souvenirs/sou_021.png',
  './picture/06-10/20260610001.jpg','./picture/06-10/20260610002.jpg',
  './picture/06-10/20260610003.jpg','./picture/06-10/20260610004.jpg',
  'https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js',
  'https://www.gstatic.com/firebasejs/9.23.0/firebase-database-compat.js'
];

self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(PRE).catch(() => {})));
});

self.addEventListener('activate', e => {
  e.waitUntil(Promise.all([
    clients.claim(),
    caches.keys().then(ks => Promise.all(ks.map(k => k !== CACHE ? caches.delete(k) : null)))
  ]));
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  if (!e.request.url.startsWith('http')) return;
  e.respondWith(
    caches.open(CACHE).then(async cache => {
      const hit = await cache.match(e.request, { ignoreSearch: true });
      const net = fetch(e.request).then(r => {
        if (r && (r.status === 200 || r.type === 'opaque')) cache.put(e.request, r.clone());
        return r;
      }).catch(() => {});
      if (hit) return hit;
      try {
        const r = await net;
        if (r) return r;
        throw new Error();
      } catch {
        if (e.request.mode === 'navigate') {
          return (await cache.match('./index.html')) || new Response('離線中', { status: 503 });
        }
        return new Response('', { status: 503 });
      }
    })
  );
});
