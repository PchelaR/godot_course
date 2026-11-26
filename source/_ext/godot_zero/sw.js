const VERSION = "__VERSION__";
const ENGINE = "__ENGINE__";
const PAGES = `pages-${VERSION}`;
const DEMOS = `demos-${ENGINE}`;
const PRECACHE = __FILES__;

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(PAGES).then((cache) => cache.addAll(PRECACHE)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== PAGES && key !== DEMOS).map((key) => caches.delete(key))))
      .then(() => self.clients.claim()),
  );
});

const remember = (name, request, response) => {
  if (response.ok) {
    const copy = response.clone();
    caches.open(name).then((cache) => cache.put(request, copy));
  }
  return response;
};

self.addEventListener("fetch", (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== "GET" || url.origin !== self.location.origin) {
    return;
  }
  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request)
        .then((response) => remember(PAGES, request, response))
        .catch(() => caches.match(request, { ignoreSearch: true })
          .then((cached) => cached || caches.match(new URL("404.html", self.registration.scope)))),
    );
    return;
  }
  const name = url.pathname.includes("/_static/godot/") ? DEMOS : PAGES;
  event.respondWith(
    caches.match(request, { ignoreSearch: true })
      .then((cached) => cached || fetch(request).then((response) => remember(name, request, response))),
  );
});
