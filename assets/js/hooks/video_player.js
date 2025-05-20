// Video player hook with quality selection support
const VideoPlayer = {
    mounted() {
        const video = this.el;

        if (Hls.isSupported()) {
            const hls = new Hls({
                startLevel: -1, // Start with auto quality
                capLevelToPlayerSize: true
            });

            hls.loadSource(video.dataset.src);
            hls.attachMedia(video);

            // Handle quality selection
            document.querySelector('select').addEventListener('change', (e) => {
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
        }
    },

    destroyed() {
        if (this.hls) {
            this.hls.destroy();
        }
    }
};

export default VideoPlayer;
