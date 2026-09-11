import { Controller } from "@hotwired/stimulus"

// Highlights the sidebar link for the current page. Done client-side so it
// also works after the sidebar is re-rendered by a Turbo Stream.
export default class extends Controller {
  connect() {
    const links = [ ...this.element.querySelectorAll("a[href]") ]
    const here = window.location.pathname + window.location.search
    const withoutView = (url) => {
      const copy = new URL(url, window.location.origin)
      copy.searchParams.delete("view")
      return copy.pathname + copy.search
    }

    const active = links.find((link) => link.pathname + link.search === here) ||
      links.find((link) => /(group|subscription)_id=/.test(link.search) && withoutView(link.href) === withoutView(window.location.href)) ||
      (window.location.pathname === "/entries" && !window.location.search && links.find((link) => link.pathname === "/"))

    links.forEach((link) => {
      link.classList.toggle("is-active", link === active)
      if (link === active) link.setAttribute("aria-current", "page")
      else link.removeAttribute("aria-current")
    })
  }
}
