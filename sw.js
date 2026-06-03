const CACHE = 'busan-pwa-v10';
const PRE = [
  './', './index.html', './manifest.json',
  './data/config.json', './data/flights.json', './data/hotels.json',
  './data/souvenirs.json', './data/todos.json', './data/checklists.json',
  './data/itinerary/2026-06-06.json', './data/itinerary/2026-06-07.json',
  './data/itinerary/2026-06-08.json', './data/itinerary/2026-06-09.json',
  './data/itinerary/2026-06-10.json',
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
