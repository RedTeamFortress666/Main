const CACHE = 'yokos-tuna-brawl-v1';
const CORE = [
  './',
  './index.html',
  './downloads.html',
  './styles.css',
  './manifest.json',
  './js/main.js',
  './js/game.js',
  './js/logic.js',
  './js/fighter.js',
  './js/render.js',
  './js/audio.js',
  './js/input.js',
  './js/ai.js',
  './assets/icon-192.png',
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    caches.match(e.request).then((hit) => hit || fetch(e.request).then((res) => {
      const copy = res.clone();
      caches.open(CACHE).then((c) => c.put(e.request, copy));
      return res;
    }).catch(() => caches.match('./index.html'))),
  );
});
