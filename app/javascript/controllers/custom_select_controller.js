import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  connect() {
    this.isOpen = false
    this.highlightedIndex = -1
    this.buildCustomUI()
    this.observeSelect()
    this.handleClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
    this.handleBeforeCache = this.teardown.bind(this)
    document.addEventListener("turbo:before-cache", this.handleBeforeCache)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
    document.removeEventListener("turbo:before-cache", this.handleBeforeCache)
    if (this.observer) this.observer.disconnect()
  }

  teardown() {
    if (this.trigger) this.trigger.remove()
    if (this.menu) this.menu.remove()
    this.selectTarget.style.display = ""
  }

  buildCustomUI() {
    const select = this.selectTarget
    select.style.display = "none"
    select.setAttribute("tabindex", "-1")

    // Build trigger button
    this.trigger = document.createElement("button")
    this.trigger.type = "button"
    this.trigger.className = "custom-select-trigger"
    if (select.disabled) this.trigger.disabled = true

    const textSpan = document.createElement("span")
    textSpan.className = "custom-select-text"
    const selectedOption = select.options[select.selectedIndex]
    textSpan.textContent = selectedOption ? selectedOption.textContent : ""

    const arrowSpan = document.createElement("span")
    arrowSpan.className = "material-icons custom-select-arrow"
    arrowSpan.textContent = "expand_more"

    this.trigger.appendChild(textSpan)
    this.trigger.appendChild(arrowSpan)

    // Build menu
    this.menu = document.createElement("ul")
    this.menu.className = "custom-select-menu"
    this.populateMenu()

    // Insert after select
    select.insertAdjacentElement("afterend", this.trigger)
    this.trigger.insertAdjacentElement("afterend", this.menu)

    // Event listeners
    this.trigger.addEventListener("click", (e) => {
      e.stopPropagation()
      this.toggle()
    })
    this.trigger.addEventListener("keydown", (e) => this.handleKeydown(e))
  }

  populateMenu() {
    this.menu.innerHTML = ""
    const select = this.selectTarget
    const options = Array.from(select.options)

    options.forEach((opt, index) => {
      const li = document.createElement("li")
      li.className = "custom-select-option"
      li.dataset.value = opt.value
      li.dataset.index = index
      li.textContent = opt.textContent

      if (index === select.selectedIndex) {
        li.classList.add("selected")
      }

      li.addEventListener("click", (e) => {
        e.stopPropagation()
        this.selectOption(index)
      })

      this.menu.appendChild(li)
    })
  }

  toggle() {
    if (this.trigger.disabled) return
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.isOpen = true
    this.menu.classList.add("open")
    this.trigger.classList.add("open")
    this.trigger.querySelector(".custom-select-arrow").textContent = "expand_less"
    this.highlightedIndex = this.selectTarget.selectedIndex
    this.updateHighlight()
    this.scrollToHighlighted()
    this.elevateCard()
  }

  close() {
    this.isOpen = false
    this.menu.classList.remove("open")
    this.trigger.classList.remove("open")
    this.trigger.querySelector(".custom-select-arrow").textContent = "expand_more"
    this.highlightedIndex = -1
    this.clearHighlight()
    this.restoreCard()
  }

  selectOption(index) {
    const select = this.selectTarget
    select.selectedIndex = index

    const selectedOption = select.options[index]
    this.trigger.querySelector(".custom-select-text").textContent = selectedOption.textContent

    // Update selected class
    this.menu.querySelectorAll(".custom-select-option").forEach((li, i) => {
      li.classList.toggle("selected", i === index)
    })

    this.close()

    // Dispatch native change event so existing controllers react
    select.dispatchEvent(new Event("change", { bubbles: true }))
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown(event) {
    const optionCount = this.selectTarget.options.length

    switch (event.key) {
      case "Enter":
      case " ":
        event.preventDefault()
        if (!this.isOpen) {
          this.open()
        } else if (this.highlightedIndex >= 0) {
          this.selectOption(this.highlightedIndex)
        }
        break
      case "Escape":
        event.preventDefault()
        this.close()
        break
      case "ArrowDown":
        event.preventDefault()
        if (!this.isOpen) {
          this.open()
        } else {
          this.highlightedIndex = (this.highlightedIndex + 1) % optionCount
          this.updateHighlight()
          this.scrollToHighlighted()
        }
        break
      case "ArrowUp":
        event.preventDefault()
        if (!this.isOpen) {
          this.open()
        } else {
          this.highlightedIndex = (this.highlightedIndex - 1 + optionCount) % optionCount
          this.updateHighlight()
          this.scrollToHighlighted()
        }
        break
      case "Tab":
        this.close()
        break
    }
  }

  updateHighlight() {
    this.menu.querySelectorAll(".custom-select-option").forEach((li, i) => {
      li.classList.toggle("highlighted", i === this.highlightedIndex)
    })
  }

  clearHighlight() {
    this.menu.querySelectorAll(".custom-select-option.highlighted").forEach((li) => {
      li.classList.remove("highlighted")
    })
  }

  scrollToHighlighted() {
    const highlighted = this.menu.querySelector(".custom-select-option.highlighted")
    if (highlighted) {
      highlighted.scrollIntoView({ block: "nearest" })
    }
  }

  observeSelect() {
    this.observer = new MutationObserver(() => {
      this.rebuildFromSelect()
    })

    this.observer.observe(this.selectTarget, {
      childList: true,
      attributes: true,
      attributeFilter: ["disabled", "selected"],
      subtree: true
    })
  }

  rebuildFromSelect() {
    const select = this.selectTarget
    this.trigger.disabled = select.disabled

    // Update trigger text
    const selectedOption = select.options[select.selectedIndex]
    this.trigger.querySelector(".custom-select-text").textContent =
      selectedOption ? selectedOption.textContent : ""

    // Rebuild menu options
    this.populateMenu()
  }

  elevateCard() {
    const card = this.element.closest(".card")
    if (card) {
      card.style.position = "relative"
      card.style.zIndex = "10"
    }
  }

  restoreCard() {
    const card = this.element.closest(".card")
    if (card) {
      card.style.position = ""
      card.style.zIndex = ""
    }
  }
}
