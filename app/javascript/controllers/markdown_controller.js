import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import DOMPurify from "dompurify"

marked.setOptions({
  breaks: true,
  gfm: true
})

export default class extends Controller {
  static values = { raw: String }

  connect() {
    this.element.innerHTML = DOMPurify.sanitize(marked.parse(this.rawValue))
  }
}
