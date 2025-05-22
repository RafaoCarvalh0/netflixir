// Video player hook with quality selection support
const VideoPlayer = {
    mounted() {
        const video = this.el;
        const playlistUrl = video.dataset.src;

        if (Hls.isSupported()) {
            const hls = new Hls({
                startLevel: -1, // Start with auto quality
                capLevelToPlayerSize: true,
                xhrSetup: (xhr, url) => {
                    // Se a URL já tem uma assinatura, usa ela como está
                    if (url.includes('?')) {
                        return;
                    }

                    // Extrai o caminho base da URL do master playlist
                    const masterUrlObj = new URL(playlistUrl);
                    const masterBasePath = masterUrlObj.pathname.split('/').slice(0, -1).join('/');

                    // Extrai o caminho relativo da URL atual
                    const currentUrlObj = new URL(url);
                    const relativePath = currentUrlObj.pathname.split('/').pop();

                    // Constrói a URL completa com a assinatura do master playlist
                    const fullUrl = `${masterUrlObj.origin}${masterBasePath}/${relativePath}${masterUrlObj.search}`;
                    xhr.open('GET', fullUrl, true);
                }
            });

            hls.loadSource(playlistUrl);
            hls.attachMedia(video);

            hls.on(Hls.Events.ERROR, (event, data) => {
                if (data.fatal) {
                    switch (data.type) {
                        case Hls.ErrorTypes.NETWORK_ERROR:
                            console.error('Network error:', data);
                            hls.startLoad();
                            break;
                        case Hls.ErrorTypes.MEDIA_ERROR:
                            console.error('Media error:', data);
                            hls.recoverMediaError();
                            break;
                        default:
                            console.error('Unrecoverable error:', data);
                            hls.destroy();
                            break;
                    }
                }
            });

            // Handle quality selection
            document.querySelector('select')?.addEventListener('change', (e) => {
                const quality = e.target.value;

                if (quality === 'auto') {
                    hls.currentLevel = -1; // -1 means auto
                    hls.autoLevelEnabled = true;
                } else {
                    const level = hls.levels.findIndex(l =>
                        l.height === parseInt(quality)
                    );

                    if (level !== -1) {
                        hls.currentLevel = level;
                        hls.autoLevelEnabled = false;
                    }
                }
            });

            // Store HLS instance for cleanup
            this.hls = hls;
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
            // For Safari on iOS
            video.src = playlistUrl;
        }
    },

    destroyed() {
        if (this.hls) {
            this.hls.destroy();
        }
    }
};

export default VideoPlayer;
