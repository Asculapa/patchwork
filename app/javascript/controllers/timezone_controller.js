import { Controller } from "@hotwired/stimulus"

// Fills the hidden time zone field with the browser's zone at sign-up.
export default class extends Controller {
  static targets = [ "field" ]

  connect() {
    const zone = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (zone) this.fieldTarget.value = zone
  }
}
