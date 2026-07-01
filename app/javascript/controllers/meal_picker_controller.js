import { Controller } from "@hotwired/stimulus"

// Fills the nutrition chat input with a scheduled meal's title when its pill is clicked.
export default class extends Controller {
  static targets = ["field"]

  fill(event) {
    const current = this.fieldTarget.value.trimEnd()
    this.fieldTarget.value = current ? `${current} ${event.params.title}` : event.params.title
    this.fieldTarget.focus()
  }
}
