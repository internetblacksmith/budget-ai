import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = { 
    autoHide: { type: Boolean, default: true },
    duration: { type: Number, default: 5000 }
  }

  connect() {
    this.createContainer()
    this.processFlashMessages()
  }

  createContainer() {
    if (!document.getElementById('toast-container')) {
      const container = document.createElement('div')
      container.id = 'toast-container'
      container.className = 'toast-container'
      document.body.appendChild(container)
    }
  }

  processFlashMessages() {
    // Process any existing flash messages and convert them to toasts
    const flashMessages = document.querySelectorAll('[data-flash-message]')
    flashMessages.forEach(flash => {
      const type = flash.classList.contains('md-snackbar-notice') ? 'success' : 'error'
      const message = flash.querySelector('.message').textContent
      
      // Create toast and remove the original flash message
      this.showToast(message, type)
      flash.remove()
    })
  }

  showToast(message, type = 'info', duration = null) {
    const container = document.getElementById('toast-container')
    const toast = this.createToastElement(message, type)
    
    container.appendChild(toast)
    
    // Trigger enter animation
    requestAnimationFrame(() => {
      toast.classList.add('toast-show')
    })
    
    // Auto-hide if enabled
    if (this.autoHideValue && duration !== 0) {
      const hideAfter = duration || this.durationValue
      setTimeout(() => {
        this.hideToast(toast)
      }, hideAfter)
    }
    
    return toast
  }

  createToastElement(message, type) {
    const toast = document.createElement('div')
    toast.className = `toast toast-${type}`
    
    const icon = this.getIconForType(type)
    
    toast.innerHTML = `
      <div class="toast-content">
        <span class="material-icons toast-icon">${icon}</span>
        <span class="toast-message">${message}</span>
        <button class="toast-close" onclick="this.closest('.toast').dispatchEvent(new CustomEvent('toast:hide'))">
          <span class="material-icons">close</span>
        </button>
      </div>
    `
    
    // Add click handler for close button
    toast.addEventListener('toast:hide', () => {
      this.hideToast(toast)
    })
    
    return toast
  }

  getIconForType(type) {
    const icons = {
      success: 'check_circle',
      error: 'error',
      warning: 'warning',
      info: 'info'
    }
    return icons[type] || 'info'
  }

  hideToast(toast) {
    toast.classList.add('toast-hide')
    toast.addEventListener('animationend', () => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast)
      }
    })
  }

  // Action methods for programmatic use
  success(event) {
    const message = event.params?.message || event.detail?.message
    if (message) this.showToast(message, 'success')
  }

  error(event) {
    const message = event.params?.message || event.detail?.message  
    if (message) this.showToast(message, 'error')
  }

  info(event) {
    const message = event.params?.message || event.detail?.message
    if (message) this.showToast(message, 'info')
  }

  warning(event) {
    const message = event.params?.message || event.detail?.message
    if (message) this.showToast(message, 'warning')
  }
}