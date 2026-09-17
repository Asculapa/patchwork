import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Collapses and expands a sidebar group (or "Other") when its name is clicked.
// The change shows at once and is saved, so it sticks across page loads and devices.
export default class extends Controller {
  async toggle(event) {
    const button = event.currentTarget
    const section = button.closest(".nav__section")
    const collapsed = section.classList.toggle("is-collapsed")
    button.setAttribute("aria-expanded", !collapsed)

    try {
      const response = await fetch(button.dataset.url, {
        method: collapsed ? "POST" : "DELETE",
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content
        },
        credentials: "same-origin"
      })
      if (!response.ok) throw new Error(`Saving the group failed: ${response.status}`)
      Turbo.renderStreamMessage(await response.text())
    } catch (error) {
      console.error(error)
      section.classList.toggle("is-collapsed", !collapsed)
      button.setAttribute("aria-expanded", collapsed)
    }
  }
}
