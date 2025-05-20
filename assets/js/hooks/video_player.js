// Video player hook with quality selection support
const VideoPlayer = {
    mounted() {
        const video = this.el;

        // Initialize HLS if supported
        if (Hls.isSupported()) {
            const hls = new Hls();
            hls.loadSource(video.dataset.src);
            hls.attachMedia(video);

            // Store HLS instance for cleanup
            this.hls = hls;

            // Handle quality changes
            this.handleEvents();
        }
    },

    handleEvents() {
        // Listen for quality change events from the select element
        document.querySelector('select').addEventListener('change', (e) => {
            const quality = e.target.value;

            if (quality === 'auto') {
                this.hls.currentLevel = -1; // -1 means auto
            } else {
                // Find the closest quality level
                const levels = this.hls.levels;
                const targetHeight = parseInt(quality);

                const selectedLevel = levels.findIndex(level =>
                    level.height === targetHeight
                );

                if (selectedLevel !== -1) {
                    this.hls.currentLevel = selectedLevel;
                }
            }
        });
    },

    destroyed() {
        if (this.hls) {
            this.hls.destroy();
        }
    }
};

export default VideoPlayer;
