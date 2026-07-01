import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js"

// Renders a dual-axis line chart of daily nutrition trends: calories on the
// left axis, the three macros (grams) on the right axis.
export default class extends Controller {
  static targets = ["canvas"]
  static values = { series: Array }

  connect() {
    const labels = this.seriesValue.map((d) => d.date)
    const line = (key, label, color, axis) => ({
      label,
      data: this.seriesValue.map((d) => d[key]),
      borderColor: color,
      backgroundColor: color,
      yAxisID: axis,
      tension: 0.3,
      pointRadius: 2
    })

    this.chart = new Chart(this.canvasTarget, {
      type: "line",
      data: {
        labels,
        // Okabe-Ito colorblind-safe palette; no red/green, distinct hues.
        datasets: [
          line("calories", "Calories", "#000000", "y"),   // black
          line("protein", "Protein (g)", "#0072b2", "y1"), // blue
          line("carbs", "Carbs (g)", "#cc79a7", "y1"),    // magenta/purple
          line("fat", "Fat (g)", "#e69f00", "y1")         // orange
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        scales: {
          y: { type: "linear", position: "left", title: { display: true, text: "Calories" } },
          y1: {
            type: "linear",
            position: "right",
            title: { display: true, text: "Grams" },
            grid: { drawOnChartArea: false }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
