import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event.stopPropagation()
    const isOpen = this.menuTarget.classList.contains("show")

    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("show")
    this.element.classList.add("expanded")
    this.outsideClickHandler = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
    setTimeout(() => document.addEventListener("click", this.outsideClickHandler), 0)
  }

  close() {
    this.menuTarget.classList.remove("show")
    this.element.classList.remove("expanded")
    if (this.outsideClickHandler) {
      document.removeEventListener("click", this.outsideClickHandler)
      this.outsideClickHandler = null
    }
  }

  disconnect() {
    if (this.outsideClickHandler) {
      document.removeEventListener("click", this.outsideClickHandler)
    }
  }
}
