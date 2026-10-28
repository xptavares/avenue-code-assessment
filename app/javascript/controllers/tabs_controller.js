import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)

    this.tabTargets.forEach((tab, i) => {
      tab.classList.toggle("border-b-2", i === index)
      tab.classList.toggle("border-black", i === index)
    })
    this.panelTargets.forEach((panel, i) => {
      panel.hidden = i !== index
    })
  }
}
