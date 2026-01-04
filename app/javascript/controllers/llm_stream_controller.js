import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import DOMPurify from "dompurify"

marked.setOptions({
  breaks: true,
  gfm: true
})

export default class extends Controller {
  static values = { url: String }
  static targets = ["output", "loading", "error", "errorMessage", "actions"]

  connect() {
    this.fullText = ""
    this.renderFrame = null
    this.startStreaming()
  }

  disconnect() {
    if (this.abortController) this.abortController.abort()
    if (this.renderFrame) cancelAnimationFrame(this.renderFrame)
  }

  async startStreaming() {
    this.abortController = new AbortController()

    try {
      const response = await fetch(this.urlValue, {
        signal: this.abortController.signal,
        headers: { "X-Requested-With": "XMLHttpRequest" }
      })

      if (!response.ok) {
        this.showError("Failed to connect to AI service.")
        return
      }

      const reader = response.body.getReader()
      const decoder = new TextDecoder()

      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        const chunk = decoder.decode(value, { stream: true })
        this.fullText += chunk

        if (this.fullText.includes("[ERROR]")) {
          const errorMsg = this.fullText.split("[ERROR]").pop()
          this.showError(errorMsg)
          return
        }

        this.scheduleRender()
      }

      this.renderMarkdown()
      if (this.hasActionsTarget) this.actionsTarget.hidden = false
    } catch (e) {
      if (e.name === "AbortError") return
      this.showError("Connection to AI service lost. Please try again.")
    }
  }

  scheduleRender() {
    if (this.renderFrame) return
    this.renderFrame = requestAnimationFrame(() => {
      this.renderFrame = null
      this.renderMarkdown()
    })
  }

  renderMarkdown() {
    this.hideLoading()
    const output = this.outputTarget
    output.hidden = false
    output.innerHTML = DOMPurify.sanitize(marked.parse(this.fullText))
  }

  showError(message) {
    this.hideLoading()
    this.outputTarget.hidden = true
    if (this.hasErrorTarget) {
      this.errorTarget.hidden = false
      if (this.hasErrorMessageTarget) {
        this.errorMessageTarget.textContent = message
      }
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) this.loadingTarget.hidden = true
  }
}
