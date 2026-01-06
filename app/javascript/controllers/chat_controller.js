import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "form", "input", "submit"]

  connect() {
    this.scrollToBottom()
  }

  send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    // Remove welcome state if present
    const welcome = document.getElementById("chat-welcome")
    if (welcome) welcome.remove()

    // Append user message immediately
    this.appendMessage("user", message)

    // Show typing indicator
    this.showTyping()

    // Disable input while waiting
    this.inputTarget.value = ""
    this.inputTarget.disabled = true
    this.submitTarget.disabled = true

    // Submit via fetch
    const formData = new FormData()
    formData.append("message", message)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.formTarget.action, {
      method: "POST",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken
      },
      body: formData
    })
    .then(response => response.text())
    .then(html => {
      this.hideTyping()
      // Remove the user message we appended (Turbo Stream will re-add it)
      const tempMessages = this.messagesTarget.querySelectorAll("[data-temp]")
      tempMessages.forEach(el => el.remove())
      // Process Turbo Stream
      Turbo.renderStreamMessage(html)
      this.scrollToBottom()
    })
    .catch(() => {
      this.hideTyping()
      this.appendMessage("assistant", "Sorry, something went wrong. Please try again.")
    })
    .finally(() => {
      this.inputTarget.disabled = false
      this.submitTarget.disabled = false
      this.inputTarget.focus()
    })
  }

  quickAction(event) {
    const message = event.currentTarget.dataset.message
    this.inputTarget.value = message
    this.formTarget.requestSubmit()
  }

  appendMessage(role, content) {
    const icon = role === "user" ? "person" : "auto_awesome"
    const html = `
      <div class="chat-message chat-message-${role}" data-temp="true">
        <div class="message-avatar">
          <span class="material-icons">${icon}</span>
        </div>
        <div class="message-bubble">
          <div class="message-content"><p>${this.escapeHtml(content)}</p></div>
        </div>
      </div>
    `
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  showTyping() {
    const html = `
      <div class="chat-message chat-message-assistant" id="typing-indicator">
        <div class="message-avatar">
          <span class="material-icons">auto_awesome</span>
        </div>
        <div class="message-bubble">
          <div class="typing-dots">
            <span></span><span></span><span></span>
          </div>
        </div>
      </div>
    `
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  hideTyping() {
    const indicator = document.getElementById("typing-indicator")
    if (indicator) indicator.remove()
  }

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    })
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
