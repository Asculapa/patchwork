import { Controller } from "@hotwired/stimulus"

// Lets the current device opt in/out of Web Push. A subscription is
// per-browser, so this reflects THIS device's state, not an account setting.
export default class extends Controller {
  static targets = [ "enableButton", "disableButton", "unsupported" ]

  async connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      this.unsupportedTarget.hidden = false
      return
    }

    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()
    this.toggle(!!subscription)
  }

  async enable() {
    const registration = await navigator.serviceWorker.ready
    const permission = await Notification.requestPermission()
    if (permission !== "granted") return

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.decodeBase64url(this.vapidPublicKey)
    })

    await fetch("/push_subscriptions", {
      method: "POST",
      headers: this.jsonHeaders,
      body: JSON.stringify(this.subscriptionParams(subscription))
    })

    this.toggle(true)
  }

  async disable() {
    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()
    if (!subscription) return

    await fetch(`/push_subscriptions/${encodeURIComponent(subscription.endpoint)}`, {
      method: "DELETE",
      headers: this.jsonHeaders
    })

    await subscription.unsubscribe()
    this.toggle(false)
  }

  toggle(enabled) {
    this.enableButtonTarget.hidden = enabled
    this.disableButtonTarget.hidden = !enabled
  }

  subscriptionParams(subscription) {
    return {
      endpoint: subscription.endpoint,
      p256dh_key: this.base64url(subscription.getKey("p256dh")),
      auth_key: this.base64url(subscription.getKey("auth"))
    }
  }

  // The webpush gem decodes these with Base64.urlsafe_decode64, so the
  // standard base64 btoa() produces (with "+"/"/") must be converted.
  base64url(buffer) {
    const base64 = btoa(String.fromCharCode(...new Uint8Array(buffer)))
    return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
  }

  decodeBase64url(base64url) {
    const base64 = (base64url + "=".repeat((4 - base64url.length % 4) % 4))
      .replace(/-/g, "+").replace(/_/g, "/")
    return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0))
  }

  get vapidPublicKey() {
    return document.querySelector('meta[name="vapid-public-key"]').content
  }

  get jsonHeaders() {
    const token = document.querySelector('meta[name="csrf-token"]').content
    return { "Content-Type": "application/json", "X-CSRF-Token": token }
  }
}
