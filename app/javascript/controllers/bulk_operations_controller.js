import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.selectAllCheckbox = document.getElementById('select-all-checkbox')
    this.checkboxes = document.querySelectorAll('.transaction-checkbox')
    this.bulkActions = document.getElementById('bulk-actions')
    this.selectedCount = document.getElementById('selected-count')
    this.bulkForm = document.getElementById('bulk-form')
    this.bulkSubmit = document.getElementById('bulk-submit')
    this.bulkActionSelect = document.getElementById('bulk-action-select')
    this.bulkTransactionIds = document.getElementById('bulk-transaction-ids')
    
    this.setupEventListeners()
    this.updateBulkActions()
  }
  
  setupEventListeners() {
    // Select all checkbox
    if (this.selectAllCheckbox) {
      this.selectAllCheckbox.addEventListener('change', (e) => {
        this.checkboxes.forEach(checkbox => {
          checkbox.checked = e.target.checked
        })
        this.updateBulkActions()
      })
    }
    
    // Individual checkboxes
    this.checkboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        this.updateBulkActions()
        this.updateSelectAllState()
      })
    })
    
    // Bulk action select
    if (this.bulkActionSelect) {
      this.bulkActionSelect.addEventListener('change', () => {
        this.bulkSubmit.disabled = !this.bulkActionSelect.value
      })
    }
    
    // Bulk form submit
    if (this.bulkForm) {
      this.bulkForm.addEventListener('submit', (e) => {
        e.preventDefault()
        const action = this.bulkActionSelect.value
        
        if (action === 'delete') {
          if (!confirm('Are you sure you want to delete the selected transactions?')) {
            return
          }
        }
        
        // Collect selected transaction IDs
        const selectedIds = Array.from(this.checkboxes)
          .filter(cb => cb.checked)
          .map(cb => cb.value)
        
        this.bulkTransactionIds.value = selectedIds.join(',')
        
        if (selectedIds.length > 0 && action) {
          this.bulkForm.submit()
        }
      })
    }
  }
  
  updateBulkActions() {
    const checkedCount = this.getCheckedCount()
    
    if (checkedCount > 0) {
      this.bulkActions.style.display = 'flex'
      this.selectedCount.textContent = checkedCount
    } else {
      this.bulkActions.style.display = 'none'
      this.bulkSubmit.disabled = true
      this.bulkActionSelect.value = ''
    }
  }
  
  updateSelectAllState() {
    const checkedCount = this.getCheckedCount()
    const totalCount = this.checkboxes.length
    
    if (this.selectAllCheckbox) {
      this.selectAllCheckbox.checked = checkedCount === totalCount && totalCount > 0
      this.selectAllCheckbox.indeterminate = checkedCount > 0 && checkedCount < totalCount
    }
  }
  
  getCheckedCount() {
    return Array.from(this.checkboxes).filter(cb => cb.checked).length
  }
}