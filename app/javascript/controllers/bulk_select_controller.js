import { Controller } from "@hotwired/stimulus"

// Powers the food-log bulk actions: a select-all checkbox, per-row checkboxes,
// and Delete/Move buttons that stay disabled until at least one row is selected.
export default class extends Controller {
  static targets = ["checkbox", "all", "submit"]

  connect() {
    this.update()
  }

  toggleAll() {
    this.checkboxTargets.forEach((cb) => {
      cb.checked = this.allTarget.checked
    })
    this.update()
  }

  update() {
    const anyChecked = this.checkboxTargets.some((cb) => cb.checked)
    this.submitTargets.forEach((button) => {
      button.disabled = !anyChecked
    })

    if (this.hasAllTarget) {
      const boxes = this.checkboxTargets
      this.allTarget.checked = boxes.length > 0 && boxes.every((cb) => cb.checked)
    }
  }
}
