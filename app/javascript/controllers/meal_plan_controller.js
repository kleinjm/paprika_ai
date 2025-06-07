import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.updatePrompt()
  }

  updatePrompt() {
    const form = document.getElementById("new_meal_plan_form")
    const data = new FormData(form)
    fetch("/home/meal_plan_prompt_preview", {
      method: "POST",
      headers: { "Accept": "text/vnd.turbo-stream.html", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content },
      body: data
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
  }
}
