import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["form"]

  updatePrompt() {
    const form = document.getElementById("meal-plan-form")
    const data = new FormData(form)
    fetch("/home/meal_plan_prompt_preview", {
      method: "POST",
      headers: { "Accept": "text/vnd.turbo-stream.html" },
      body: data
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
  }
}
