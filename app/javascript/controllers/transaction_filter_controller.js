import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["form", "showFilter", "accountFilter", "categoryFilter", "searchFilter", "amountFilter"]

  filterChanged() {
    if ((this.hasSearchFilterTarget && event.target === this.searchFilterTarget) ||
        (this.hasAmountFilterTarget && event.target === this.amountFilterTarget)) {
      clearTimeout(this.searchTimeout)
      this.searchTimeout = setTimeout(() => {
        this.submitForm()
      }, 300)
    } else {
      this.submitForm()
    }
  }

  submitForm() {
    const formData = new FormData(this.formTarget)
    const params = new URLSearchParams(window.location.search)

    const filterKeys = ['show', 'account', 'category', 'search', 'amount']

    filterKeys.forEach(key => {
      const value = formData.get(key)
      if (value && value.trim() !== '') {
        params.set(key, value)
      } else {
        params.delete(key)
      }
    })

    // Reset to page 1 when filters change
    params.delete('page')

    const baseUrl = this.formTarget.action
    const newUrl = params.toString() ? `${baseUrl}?${params.toString()}` : baseUrl

    history.replaceState(history.state, "", newUrl)

    this.formTarget.requestSubmit()
  }

  clearFilters(event) {
    event.preventDefault()

    if (this.hasShowFilterTarget) this.showFilterTarget.value = ""
    if (this.hasAccountFilterTarget) this.accountFilterTarget.value = ""
    if (this.hasCategoryFilterTarget) this.categoryFilterTarget.value = ""
    if (this.hasSearchFilterTarget) this.searchFilterTarget.value = ""
    if (this.hasAmountFilterTarget) this.amountFilterTarget.value = ""

    const params = new URLSearchParams(window.location.search)
    const filterKeys = ['show', 'account', 'category', 'search', 'amount']
    filterKeys.forEach(key => params.delete(key))
    params.delete('page')

    const baseUrl = this.formTarget.action
    const newUrl = params.toString() ? `${baseUrl}?${params.toString()}` : baseUrl
    history.replaceState(history.state, "", newUrl)

    this.formTarget.requestSubmit()
  }

  changePerPage(event) {
    event.preventDefault()
    const perPage = event.target.value

    const params = new URLSearchParams(window.location.search)
    params.set('per', perPage)
    params.delete('page')

    const baseUrl = this.formTarget.action
    const newUrl = params.toString() ? `${baseUrl}?${params.toString()}` : baseUrl

    Turbo.visit(newUrl)
  }
}
