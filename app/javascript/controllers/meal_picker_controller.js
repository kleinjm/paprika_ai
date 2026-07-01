import { Controller } from "@hotwired/stimulus"

// Builds the nutrition chat input from portion/meal pills and the recipe
// dropdown, tracking which Paprika recipe ids were picked via hidden fields.
export default class extends Controller {
  static targets = ["field"]

  // Portion and meal pills.
  fill(event) {
    this.appendText(event.params.title)
    if (event.params.recipeId) this.addRecipe(event.params.recipeId)
  }

  // "Add another recipe…" dropdown.
  pick(event) {
    const option = event.target.selectedOptions[0]
    if (!option || !option.value) return

    this.appendText(option.dataset.title || option.text)
    this.addRecipe(option.value)
    event.target.selectedIndex = 0
  }

  // Drop the tracked recipe ids after a successful submit.
  clear(event) {
    if (event.detail.success) {
      this.element.querySelectorAll("input[name='recipe_ids[]']").forEach((el) => el.remove())
    }
  }

  appendText(text) {
    const current = this.fieldTarget.value.trimEnd()
    this.fieldTarget.value = current ? `${current} ${text}` : text
    this.fieldTarget.focus()
  }

  addRecipe(id) {
    if (this.element.querySelector(`input[name='recipe_ids[]'][value='${id}']`)) return

    const input = document.createElement("input")
    input.type = "hidden"
    input.name = "recipe_ids[]"
    input.value = id
    this.element.appendChild(input)
  }
}
