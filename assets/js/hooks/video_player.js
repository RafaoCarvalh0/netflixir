const VideoPlayer = {
    mounted() {
        this.initializePlayer();
    },
    updated() {
        this.initializePlayer();
    },
    initializePlayer() {
        const video = this.el;
        const videoSrc = video.dataset.src;

        if (Hls.isSupported()) {
            const hls = new Hls({
                debug: true,
                enableWorker: true,
                startLevel: -1,
            });

            hls.loadSource(videoSrc);
            hls.attachMedia(video);

            hls.on(Hls.Events.MANIFEST_PARSED, function () {
                console.log('HLS manifest parsed, trying to play...');
                video.play().catch(function (error) {
                    console.log("Play failed:", error);
                });
            });

            hls.on(Hls.Events.ERROR, function (event, data) {
                console.log('HLS error:', data);
                if (data.fatal) {
                    switch (data.type) {
                        case Hls.ErrorTypes.NETWORK_ERROR:
                            hls.startLoad();
                            break;
                        case Hls.ErrorTypes.MEDIA_ERROR:
                            hls.recoverMediaError();
                            break;
                        default:
                            hls.destroy();
                            break;
                    }
                }
            });
        } else {
            console.error('HLS.js not supported');
        }
    }
}

export default VideoPlayer;
