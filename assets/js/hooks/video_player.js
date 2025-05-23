// Video player hook with quality selection support
const VideoPlayer = {
    mounted() {
        const video = this.el;
        let playlistUrl = video.dataset.src;

        if (Hls.isSupported()) {
            const hls = new Hls({
                startLevel: -1, // Start with auto quality
                capLevelToPlayerSize: true,
                xhrSetup: async (xhr, url) => {
                    // Se não for uma URL HTTP (arquivo local), usa um caminho absoluto
                    if (!url.startsWith('http')) {
                        url = `${window.location.origin}/storage/dev/${url}`;
                    }

                    // Solicita uma URL assinada para este arquivo específico
                    const response = await this.pushEventTo(this.el, "get_signed_url", { path: url });
                    if (response && response.url) {
                        url = response.url;
                    }

                    // Abre a requisição com a URL final
                    xhr.open('GET', url, true);
                }
            });

            // Se não for uma URL HTTP (arquivo local), usa um caminho absoluto
            if (!playlistUrl || !playlistUrl.startsWith('http')) {
                const baseUrl = `${window.location.origin}/storage/dev/`;
                playlistUrl = playlistUrl ? baseUrl + playlistUrl : null;
            }

            if (!playlistUrl) {
                console.error('No playlist URL available!');
                return;
            }

            hls.loadSource(playlistUrl);
            hls.attachMedia(video);

            hls.on(Hls.Events.ERROR, (event, data) => {
                if (data.fatal) {
                    console.error('Fatal error:', data);
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
