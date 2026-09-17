import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const DRAG_DISTANCE = 5    // px a mouse must move before a press becomes a drag
const LONG_PRESS = 350     // ms a finger must rest on an item before it can be dragged
const TOUCH_SLOP = 10      // px a finger may wander during the long press
const EDGE = 40            // px from the scroller's edge where auto-scroll kicks in

// Rearranges the sidebar by drag and drop: groups by their name, sources within
// or between groups. Mouse drags start after a small movement; touch drags need
// a long press so swiping still scrolls. The server replies with the re-rendered
// sidebar, which also refreshes the group unread counts.
export default class extends Controller {
  connect() {
    this.onMove = this.move.bind(this)
    this.onUp = this.drop.bind(this)
    this.onCancel = () => this.cancel()
    this.onKey = (event) => { if (event.key === "Escape") this.cancel() }
    this.onTouchMove = (event) => { if (this.dragging) event.preventDefault() }
    this.onContextMenu = (event) => { if (this.pending || this.dragging) event.preventDefault() }
    window.addEventListener("touchmove", this.onTouchMove, { passive: false })
    window.addEventListener("contextmenu", this.onContextMenu)
  }

  disconnect() {
    this.cancel()
    window.removeEventListener("touchmove", this.onTouchMove)
    window.removeEventListener("contextmenu", this.onContextMenu)
  }

  preventNativeDrag(event) {
    event.preventDefault()
  }

  press(event) {
    if (!event.isPrimary || event.button !== 0 || this.pending || this.dragging) return
    const handle = event.target.closest("[data-sortable-handle]")
    if (!handle) return

    this.pending = {
      item: handle.closest("[data-sortable-source], [data-sortable-group]"),
      touch: event.pointerType !== "mouse",
      x: event.clientX,
      y: event.clientY
    }
    if (this.pending.touch) this.pressTimer = setTimeout(() => this.start(), LONG_PRESS)

    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    window.addEventListener("pointercancel", this.onCancel)
    window.addEventListener("keydown", this.onKey)
  }

  start() {
    const { item } = this.pending
    this.dragging = {
      item,
      kind: item.hasAttribute("data-sortable-group") ? "group" : "source",
      origin: { parent: item.parentNode, next: item.nextSibling },
      y: this.pending.y
    }
    this.pending = null
    this.scroller = this.element.closest(".sidebar") || this.element

    // Collapse sources while moving a group so groups are easy to reorder, and
    // keep the dragged group under the pointer as the list shrinks.
    const before = item.getBoundingClientRect().top
    this.element.classList.add("is-sorting", `is-sorting-${this.dragging.kind}s`)
    item.classList.add("is-dragging")
    this.scroller.scrollTop += item.getBoundingClientRect().top - before

    if (navigator.vibrate) navigator.vibrate(10)
    this.autoScroll()
  }

  move(event) {
    if (!event.isPrimary) return

    if (this.pending) {
      const distance = Math.hypot(event.clientX - this.pending.x, event.clientY - this.pending.y)
      if (this.pending.touch) {
        if (distance > TOUCH_SLOP) this.release() // the finger is scrolling
      } else if (distance > DRAG_DISTANCE) {
        this.start()
      }
      if (!this.dragging) return
    }

    this.dragging.y = event.clientY
    this.reposition()
  }

  reposition() {
    const { item, kind, y } = this.dragging

    if (kind === "group") {
      const groups = [ ...this.element.querySelectorAll("[data-sortable-group]") ].filter((group) => group !== item)
      const next = groups.find((group) => y < midpoint(group))
      if (next) {
        if (item.nextElementSibling !== next) next.before(item)
      } else if (groups.length) {
        groups.at(-1).after(item)
      }
    } else {
      const lists = [ ...this.element.querySelectorAll("[data-sortable-sources]") ]
      const list = lists.findLast((list) => list.parentElement.getBoundingClientRect().top <= y) || lists[0]
      const next = [ ...list.children ].find((source) => source !== item && y < midpoint(source))
      if (next) {
        if (item.nextElementSibling !== next) next.before(item)
      } else if (list.lastElementChild !== item) {
        list.append(item)
      }
    }
  }

  async drop(event) {
    if (!event.isPrimary) return
    const dragging = this.dragging
    this.release()
    if (!dragging) return

    this.swallowNextClick()
    const { item, kind, origin } = dragging
    if (item.parentNode === origin.parent && item.nextSibling === origin.next) return

    const body = new FormData()
    if (kind === "group") {
      body.append("position", [ ...this.element.querySelectorAll("[data-sortable-group]") ].indexOf(item))
    } else {
      body.append("position", [ ...item.parentNode.children ].indexOf(item))
      body.append("group_id", item.parentNode.dataset.groupId ?? "")
    }

    try {
      const response = await fetch(item.dataset.url, {
        method: "PATCH",
        body,
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content
        },
        credentials: "same-origin"
      })
      if (!response.ok) throw new Error(`Reordering failed: ${response.status}`)
      Turbo.renderStreamMessage(await response.text())
    } catch (error) {
      console.error(error)
      restore(item, origin)
    }
  }

  cancel() {
    const dragging = this.dragging
    this.release()
    if (dragging) restore(dragging.item, dragging.origin)
  }

  release() {
    clearTimeout(this.pressTimer)
    cancelAnimationFrame(this.scrollFrame)
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onCancel)
    window.removeEventListener("keydown", this.onKey)

    this.dragging?.item.classList.remove("is-dragging")
    this.element.classList.remove("is-sorting", "is-sorting-groups", "is-sorting-sources")
    this.pending = null
    this.dragging = null
  }

  // Scrolls the sidebar while the pointer rests near its top or bottom edge.
  autoScroll() {
    if (!this.dragging) return
    const { top, bottom } = this.scroller.getBoundingClientRect()
    const y = this.dragging.y
    const speed = y < top + EDGE ? -(top + EDGE - y) : y > bottom - EDGE ? y - (bottom - EDGE) : 0
    if (speed) {
      this.scroller.scrollTop += Math.round(speed / 3)
      this.reposition()
    }
    this.scrollFrame = requestAnimationFrame(() => this.autoScroll())
  }

  // The pointerup that ends a drag is followed by a click on the link; don't navigate.
  swallowNextClick() {
    const swallow = (event) => {
      event.preventDefault()
      event.stopPropagation()
    }
    window.addEventListener("click", swallow, { capture: true, once: true })
    setTimeout(() => window.removeEventListener("click", swallow, { capture: true }), 0)
  }
}

function midpoint(element) {
  const { top, height } = element.getBoundingClientRect()
  return top + height / 2
}

function restore(item, { parent, next }) {
  parent.insertBefore(item, next)
}
