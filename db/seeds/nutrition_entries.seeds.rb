# Backfill 30 days of mock nutrition entries so the tracker and history/chart
# have data to display. Idempotent: clears the same 30-day window first.
# Runs after the user seed since the entries belong to that user.
#
# Each day's totals are deterministic (no RNG, so re-seeding is stable) and land
# in a realistic range: 2000-3200 kcal and 80-180 g protein. Per-day totals are
# split exactly across the day's meals so the sums stay in range.
after "users" do
  email = Rails.application.credentials.dig(:user, :email).presence || "demo@example.com"
  user = User.find_by!(email: email)

  dishes = [
    "Scrambled eggs and toast", "Greek yogurt with granola", "Grilled chicken and rice bowl",
    "Protein shake with banana", "Beef chili", "Salmon, quinoa, and broccoli",
    "Peanut butter apple snack", "Turkey sandwich", "Bean and veggie burrito", "Cottage cheese and berries"
  ]

  meals_per_day = 4
  # Divide value across n meals as integers that sum exactly to value.
  split = ->(value, i, n) { (value / n) + (i < (value % n) ? 1 : 0) }

  start_date = Date.current - 29
  user.nutrition_entries.where(logged_on: start_date..Date.current).destroy_all

  (start_date..Date.current).each do |day|
    calories = 2000 + (day.yday * 137) % 1201  # 2000..3200
    protein  = 80 + (day.yday * 53) % 101      # 80..180

    # Fill the remaining calories with carbs/fat, then derive the minor nutrients.
    remaining = [ calories - (protein * 4), 0 ].max
    day_totals = {
      calories: calories,
      protein: protein,
      carbs: (remaining * 0.55 / 4).round,
      fat: (remaining * 0.45 / 9).round
    }
    day_totals[:fiber] = (day_totals[:carbs] / 8.0).round
    day_totals[:saturated_fat] = (day_totals[:fat] / 3.0).round
    day_totals[:sugar] = (day_totals[:carbs] / 4.0).round

    meals_per_day.times do |i|
      attrs = day_totals.transform_values { |value| split.call(value, i, meals_per_day) }
      user.nutrition_entries.create!(
        attrs.merge(item: dishes[(day.yday + i) % dishes.size], logged_on: day, raw_input: "seed")
      )
    end
  end

  count = user.nutrition_entries.where(logged_on: start_date..Date.current).count
  puts "Seeded #{count} nutrition entries for #{user.email} (#{start_date} through #{Date.current})."
end
