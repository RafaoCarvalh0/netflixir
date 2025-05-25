// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import VideoPlayer from "./hooks/video_player"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {
  VideoPlayer: VideoPlayer,
  AutoHideFlash: {
    mounted() {
      setTimeout(() => {
        this.el.style.display = "none";
      }, 2000);
    }
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js')
      .then(reg => console.log('Service Worker registered!', reg))
      .catch(err => console.error('Error registering Service Worker:', err));
  });
}

window.addEventListener("phx:set-jwt-cookie", (e) => {
  const token = e.detail.token;
  const form = document.createElement("form");
  form.method = "POST";
  form.action = "/set_jwt";
  const input = document.createElement("input");
  input.type = "hidden";
  input.name = "token";
  input.value = token;
  form.appendChild(input);

  // Adiciona o CSRF token
  const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
  const csrfInput = document.createElement("input");
  csrfInput.type = "hidden";
  csrfInput.name = "_csrf_token";
  csrfInput.value = csrfToken;
  form.appendChild(csrfInput);

  document.body.appendChild(form);
  form.submit();
});

// Handle logout
window.addEventListener("phx:logout", () => {
  document.cookie = "user_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
  window.location.href = "/";
});

