import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "spreadsheetSelect",
    "sheetSelect",
    "importButton",
    "accountBar",
    "accountInfo",
    "accountError",
    "errorMessage",
    "retryButton",
    "selectorsContainer",
    "spreadsheetId",
    "sheetName"
  ]

  static values = {
    reconnectUrl: String
  }

  connect() {
    this.fetchSpreadsheets()
  }

  retry() {
    this.fetchSpreadsheets()
  }

  async fetchSpreadsheets() {
    this.spreadsheetSelectTarget.disabled = true
    this.spreadsheetSelectTarget.innerHTML = '<option value="">Loading spreadsheets...</option>'
    this.resetSheetSelect()
    this.disableImportButton()
    this.hideError()

    try {
      const response = await fetch("/imports/list_spreadsheets")
      const data = await response.json()

      if (data.error) {
        this.showError(data.error)
        this.spreadsheetSelectTarget.innerHTML = '<option value="">Unavailable</option>'
        return
      }

      this.spreadsheetSelectTarget.innerHTML = '<option value="">Select a spreadsheet...</option>'
      data.forEach(s => {
        const opt = document.createElement("option")
        opt.value = s.id
        opt.textContent = s.name
        this.spreadsheetSelectTarget.appendChild(opt)
      })
      this.spreadsheetSelectTarget.disabled = false
    } catch (e) {
      this.showError(`Failed to load spreadsheets: ${e.message}`)
      this.spreadsheetSelectTarget.innerHTML = '<option value="">Unavailable</option>'
    }
  }

  async selectSpreadsheet() {
    const spreadsheetId = this.spreadsheetSelectTarget.value

    this.resetSheetSelect()
    this.disableImportButton()

    if (!spreadsheetId) return

    this.sheetSelectTarget.innerHTML = '<option value="">Loading sheets...</option>'
    this.hideError()

    try {
      const url = `/imports/list_spreadsheet_sheets?spreadsheet_id=${encodeURIComponent(spreadsheetId)}`
      const response = await fetch(url)
      const data = await response.json()

      if (data.error) {
        this.showError(data.error)
        this.sheetSelectTarget.innerHTML = '<option value="">Unavailable</option>'
        return
      }

      this.sheetSelectTarget.innerHTML = '<option value="">Select a sheet...</option>'
      data.forEach(s => {
        const opt = document.createElement("option")
        opt.value = s.title
        opt.textContent = s.title
        this.sheetSelectTarget.appendChild(opt)
      })
      this.sheetSelectTarget.disabled = false
    } catch (e) {
      this.showError(`Failed to load sheets: ${e.message}`)
      this.sheetSelectTarget.innerHTML = '<option value="">Unavailable</option>'
    }
  }

  selectSheet() {
    if (this.sheetSelectTarget.value) {
      this.importButtonTarget.disabled = false
    } else {
      this.disableImportButton()
    }
  }

  submitImport() {
    const spreadsheetId = this.spreadsheetSelectTarget.value
    const sheetName = this.sheetSelectTarget.value

    if (!spreadsheetId || !sheetName) return

    this.spreadsheetIdTarget.value = spreadsheetId
    this.sheetNameTarget.value = sheetName
    this.spreadsheetIdTarget.closest("form").requestSubmit()
  }

  // Private helpers

  resetSheetSelect() {
    this.sheetSelectTarget.innerHTML = '<option value="">Select a spreadsheet first</option>'
    this.sheetSelectTarget.disabled = true
  }

  disableImportButton() {
    this.importButtonTarget.disabled = true
  }

  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
    }
    if (this.hasAccountInfoTarget) this.accountInfoTarget.hidden = true
    if (this.hasAccountErrorTarget) this.accountErrorTarget.hidden = false
    if (this.hasRetryButtonTarget) this.retryButtonTarget.hidden = false
    if (this.hasAccountBarTarget) this.accountBarTarget.classList.add("import-account-bar-error")
  }

  hideError() {
    if (this.hasAccountInfoTarget) this.accountInfoTarget.hidden = false
    if (this.hasAccountErrorTarget) this.accountErrorTarget.hidden = true
    if (this.hasRetryButtonTarget) this.retryButtonTarget.hidden = true
    if (this.hasAccountBarTarget) this.accountBarTarget.classList.remove("import-account-bar-error")
  }
}
