import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    jobId: Number,
    status: String
  }

  static targets = ["progressBar", "progressText"]

  connect() {
    this.animateEntrance()

    if (this.isInProgress()) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  statusValueChanged() {
    if (this.isInProgress()) {
      this.startPolling()
    } else {
      this.stopPolling()
    }
  }

  dismiss() {
    const container = document.getElementById("import-progress-bar")
    if (container) delete container.dataset.animated

    const bar = this.element.querySelector(".import-bar")
    if (bar) {
      bar.classList.add("import-bar-slide-down")
      bar.addEventListener("animationend", () => this.element.remove(), { once: true })
    } else {
      this.element.remove()
    }
  }

  animateEntrance() {
    const container = document.getElementById("import-progress-bar")
    if (!container || container.dataset.animated) return

    container.dataset.animated = "true"
    const bar = this.element.querySelector(".import-bar")
    if (bar) bar.classList.add("import-bar-slide-up")
  }

  isInProgress() {
    return ["pending", "processing"].includes(this.statusValue)
  }

  startPolling() {
    if (this.pollTimer) return

    this.pollTimer = setInterval(() => {
      this.checkStatus()
    }, 3000)
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
  }

  updateProgress(imported, total) {
    const percentage = Math.round((imported / total) * 100)

    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percentage}%`
    }

    if (this.hasProgressTextTarget) {
      const importedStr = imported.toLocaleString()
      const totalStr = total.toLocaleString()
      this.progressTextTarget.textContent = `${importedStr} / ${totalStr} transactions imported`
    }
  }

  async checkStatus() {
    try {
      const response = await fetch("/imports/check_import_status", {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) return

      const data = await response.json()
      if (data.status === "none") return

      if (data.status === "processing" && data.total_count) {
        this.updateProgress(data.imported_count || 0, data.total_count)
      }

      const finishedStatuses = ["completed", "completed_with_errors", "failed"]
      if (finishedStatuses.includes(data.status)) {
        this.stopPolling()
        // Turbo Stream should have already updated the DOM.
        // If not, reload the section.
        if (this.isInProgress()) {
          window.location.reload()
        }
      }
    } catch (error) {
      // Silently ignore polling errors
    }
  }
}
