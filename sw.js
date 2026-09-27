const CACHE='malama-v3-20260928-3';
const CORE=['./','./index.html','./manifest.json'];
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE)))});
self.addEventListener('activate',e=>{e.waitUntil(Promise.all([caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))),self.clients.claim()]))});
self.addEventListener('fetch',e=>{if(e.request.method!=='GET')return;const u=new URL(e.request.url);if(u.origin===location.origin&&(u.pathname.endsWith('/')||u.pathname.endsWith('/index.html'))){e.respondWith(fetch(e.request).then(r=>{const x=r.clone();caches.open(CACHE).then(c=>c.put(e.request,x));return r}).catch(()=>caches.match(e.request)));return}e.respondWith(caches.match(e.request).then(c=>c||fetch(e.request).then(r=>{if(u.origin===location.origin){const x=r.clone();caches.open(CACHE).then(cc=>cc.put(e.request,x))}return r})))});
