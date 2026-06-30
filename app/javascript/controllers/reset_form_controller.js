import { Controller } from "@hotwired/stimulus"

// Clears the chat input after a successful turbo form submission.
export default class extends Controller {
  reset(event) {
    if (event.detail.success) {
      this.element.reset()
    }
  }
}
