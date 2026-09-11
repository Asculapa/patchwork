import { Controller } from "@hotwired/stimulus"

// Opens and closes the sidebar on narrow screens.
export default class extends Controller {
  static classes = [ "open" ]

  toggle() {
    this.element.classList.toggle(this.openClass)
  }
}
