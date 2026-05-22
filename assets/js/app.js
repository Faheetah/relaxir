// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import live_select from "live_select"

let ClipboardPaste = {
  mounted() {
    this.handlePaste = (event) => {
      const items = event.clipboardData.items
      const files = []

      for (let i = 0; i < items.length; i++) {
        const item = items[i]
        if (item.kind === "file" && item.type.startsWith("image/")) {
          const file = item.getAsFile()
          if (file) files.push(file)
        }
      }

      if (files.length > 0) {
        event.preventDefault()

        const dt = new DataTransfer()
        files.forEach(file => dt.items.add(file))

        const dropEvent = new DragEvent("drop", {
          bubbles: true,
          cancelable: true,
          dataTransfer: dt
        })

        this.el.dispatchEvent(dropEvent)
      }
    }

    this.handleDragOver = () => {
      this.el.classList.add("border-amber-500", "bg-amber-50")
      this.el.classList.remove("border-neutral-300", "bg-white")
    }

    this.handleDragLeave = () => {
      this.el.classList.remove("border-amber-500", "bg-amber-50")
      this.el.classList.add("border-neutral-300", "bg-white")
    }

    document.addEventListener("paste", this.handlePaste)
    this.el.addEventListener("dragover", this.handleDragOver)
    this.el.addEventListener("dragleave", this.handleDragLeave)
  },

  destroyed() {
    document.removeEventListener("paste", this.handlePaste)
    this.el.removeEventListener("dragover", this.handleDragOver)
    this.el.removeEventListener("dragleave", this.handleDragLeave)
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
    longPollFallbackMs: 2500,
    params: {_csrf_token: csrfToken},
    hooks: {...live_select, ClipboardPaste}
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
