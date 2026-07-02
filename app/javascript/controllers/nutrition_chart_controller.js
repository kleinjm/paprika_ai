import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js"

// Renders a dual-axis line chart of daily nutrition trends: calories on the
// left axis, the three macros (grams) on the right axis. When goals are set,
// a flat dashed line (a lighter shade of each nutrient) marks the target.
export default class extends Controller {
  static targets = ["canvas"]
  static values = { series: Array, goals: Object }

  // key, label, solid color, lighter goal-line shade, axis
  static NUTRIENTS = [
    { key: "calories", label: "Calories", color: "#000000", goalColor: "#999999", axis: "y" },
    { key: "protein", label: "Protein (g)", color: "#0072b2", goalColor: "#7fb8dc", axis: "y1" },
    { key: "carbs", label: "Carbs (g)", color: "#cc79a7", goalColor: "#e6bcd3", axis: "y1" },
    { key: "fat", label: "Fat (g)", color: "#e69f00", goalColor: "#f2cf80", axis: "y1" }
  ]

  connect() {
    const labels = this.seriesValue.map((d) => d.date)
    const goals = this.goalsValue

    const datasets = []
    this.constructor.NUTRIENTS.forEach((n) => {
      datasets.push({
        label: n.label,
        data: this.seriesValue.map((d) => d[n.key]),
        borderColor: n.color,
        backgroundColor: n.color,
        yAxisID: n.axis,
        tension: 0.3,
        pointRadius: 2
      })

      const goal = goals[n.key]
      if (goal != null) {
        datasets.push({
          label: `${n.label} goal`,
          data: labels.map(() => goal),
          borderColor: n.goalColor,
          borderDash: [6, 4],
          borderWidth: 2.5,
          pointRadius: 0,
          fill: false,
          yAxisID: n.axis
        })
      }
    })

    this.chart = new Chart(this.canvasTarget, {
      type: "line",
      data: { labels, datasets },
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
