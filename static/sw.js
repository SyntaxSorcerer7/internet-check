const CACHE_NAME = 'internet-monitor-v1';
const urlsToCache = [
  '/',
  '/manifest.json',
  'https://cdn.jsdelivr.net/npm/chart.js',
  'https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3'
];

// Installation
self.addEventListener('install', event => {
  console.log('Service Worker installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Cache geöffnet');
        // Nur grundlegende URLs cachen, um Fehler zu vermeiden
        return cache.addAll(['/']);
      })
      .catch(err => {
        console.log('Cache installation failed:', err);
      })
  );
  // Sofort aktivieren
  self.skipWaiting();
});

// Activate
self.addEventListener('activate', event => {
  console.log('Service Worker activating...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      // Sofort alle Clients übernehmen
      return self.clients.claim();
    })
  );
});

// Fetch Events - Einfache Strategie für localhost
self.addEventListener('fetch', event => {
  // Nur für same-origin requests
  if (event.request.url.startsWith(self.location.origin)) {
    event.respondWith(
      fetch(event.request)
        .then(response => {
          // Erfolgreiche Antwort klonen und cachen
          if (response.status === 200) {
            const responseToCache = response.clone();
            caches.open(CACHE_NAME)
              .then(cache => {
                cache.put(event.request, responseToCache);
              });
          }
          return response;
        })
        .catch(() => {
          // Bei Netzwerkfehler aus Cache laden
          return caches.match(event.request);
        })
    );
  }
});
