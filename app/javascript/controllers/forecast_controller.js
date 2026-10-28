import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "result"]

  async submit(event) {
    event.preventDefault()

    const params = new URLSearchParams(new FormData(this.formTarget))
    this.resultTarget.textContent = "Loading..."

    try {
      const response = await fetch(`${this.formTarget.action}?${params}`, { headers: { Accept: "application/json" } })
      const data = await response.json()

      if (response.ok) {
        this.render(data)
      } else {
        this.showError(data.error)
      }
    } catch {
      this.showError("Something went wrong. Please try again.")
    }
  }

  render(data) {
    const [today, ...nextDays] = data.days

    this.resultTarget.innerHTML = `
      <h2 class="text-2xl font-bold mb-2">Forecast for ${escapeHTML(data.address)}</h2>
      ${data.cached ? `
        <div class="my-4 rounded border border-yellow-400 bg-yellow-100 p-3">
          <p class="font-semibold">Cached result</p>
          <p>Fetched ${minutes(Date.now() - Date.parse(data.fetched_at))} ago. Refreshes in ${minutes(Date.parse(data.expires_at) - Date.now())}.</p>
        </div>` : `
        <div class="my-4 rounded border border-green-400 bg-green-100 p-3">
          <p class="font-semibold">Fresh result</p>
          <p>Fetched just now from the weather service.</p>
        </div>`}

      <h3 class="text-xl font-semibold mt-6 mb-2">Today, ${formatDate(today.date, { month: "long", day: "numeric", year: "numeric" })}</h3>
      <p>Now: ${temperature(data.current_temperature)}</p>
      <p>High: ${temperature(today.high)} / Low: ${temperature(today.low)}</p>
      <p>Chance of rain: ${today.precipitation_probability ?? "-"}% (${today.precipitation_sum ?? "-"} mm)</p>

      <h4 class="text-lg font-semibold mt-6 mb-2">Hourly</h4>
      <table class="w-full text-left">
        <thead>
          <tr class="border-b"><th>Hour</th><th>Temperature</th><th>Chance of rain</th><th>Precipitation</th></tr>
        </thead>
        <tbody>
          ${today.hours.map((hour) => `
            <tr class="border-b">
              <td>${hour.time.slice(11, 16)}</td>
              <td>${temperature(hour.temperature)}</td>
              <td>${hour.precipitation_probability ?? "-"}%</td>
              <td>${hour.precipitation ?? "-"} mm</td>
            </tr>`).join("")}
        </tbody>
      </table>

      <h3 class="text-xl font-semibold mt-6 mb-2">Next days</h3>
      <table class="w-full text-left">
        <thead>
          <tr class="border-b"><th>Date</th><th>High</th><th>Low</th><th>Chance of rain</th><th>Precipitation</th></tr>
        </thead>
        <tbody>
          ${nextDays.map((day) => `
            <tr class="border-b">
              <td>${formatDate(day.date, { weekday: "short", month: "short", day: "numeric" })}</td>
              <td>${temperature(day.high)}</td>
              <td>${temperature(day.low)}</td>
              <td>${day.precipitation_probability ?? "-"}%</td>
              <td>${day.precipitation_sum ?? "-"} mm</td>
            </tr>`).join("")}
        </tbody>
      </table>
    `
  }

  showError(message) {
    this.resultTarget.innerHTML = `<p class="text-red-600">${escapeHTML(message)}</p>`
  }
}

function minutes(milliseconds) {
  const count = Math.round(milliseconds / 60000)
  if (count < 1) return "less than a minute"
  return count === 1 ? "1 minute" : `${count} minutes`
}

function temperature(value) {
  return value == null ? "-" : `${Math.round(value)}°C`
}

// Dates come as "YYYY-MM-DD"; parsing them as local midnight avoids shifting a day in negative UTC offsets
function formatDate(date, options) {
  return new Date(`${date}T00:00:00`).toLocaleDateString("en-US", options)
}

function escapeHTML(value) {
  const element = document.createElement("div")
  element.textContent = value
  return element.innerHTML
}
