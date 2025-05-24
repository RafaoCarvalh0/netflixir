const CACHE_NAME = 'media-cache-v1';
const MEDIA_EXTENSIONS = ['.webp', '.jpg', '.jpeg', '.png', '.gif', '.m3u8', '.ts'];

self.addEventListener('fetch', (event) => {
    const { request } = event;

    // Only intercept GET requests for media files (images + HLS)
    if (
        request.method === 'GET' &&
        MEDIA_EXTENSIONS.some(ext => request.url.endsWith(ext))
    ) {
        event.respondWith(
            caches.open(CACHE_NAME).then(async (cache) => {
                const cachedResponse = await cache.match(request);
                if (cachedResponse) {
                    return cachedResponse;
                }
                const response = await fetch(request);
                // Only cache if response is valid
                if (response.status === 200) {
                    cache.put(request, response.clone());
                }
                return response;
            })
        );
    }
    // Otherwise, do nothing (let the request go to the network)
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then(keys =>
            Promise.all(
                keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))
            )
        )
    );
}); 