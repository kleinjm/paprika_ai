# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Backfill 30 days of mock nutrition entries so the tracker and history/chart
# have data to display. Idempotent: clears the same 30-day window first.
mock_foods = [
  { item: "Scrambled eggs and toast",       calories: 340, protein: 22, carbs: 28, fat: 15, fiber: 3,  saturated_fat: 5, sugar: 4 },
  { item: "Greek yogurt with granola",       calories: 410, protein: 24, carbs: 52, fat: 11, fiber: 5,  saturated_fat: 3, sugar: 18 },
  { item: "Grilled chicken and rice bowl",   calories: 620, protein: 48, carbs: 60, fat: 18, fiber: 4,  saturated_fat: 4, sugar: 3 },
  { item: "Protein shake with banana",       calories: 300, protein: 35, carbs: 34, fat: 4,  fiber: 3,  saturated_fat: 1, sugar: 20 },
  { item: "Beef chili, medium bowl",         calories: 540, protein: 38, carbs: 40, fat: 24, fiber: 9,  saturated_fat: 9, sugar: 7 },
  { item: "Salmon, quinoa, and broccoli",    calories: 580, protein: 42, carbs: 45, fat: 24, fiber: 8,  saturated_fat: 5, sugar: 4 },
  { item: "Peanut butter apple snack",       calories: 285, protein: 8,  carbs: 33, fat: 16, fiber: 6,  saturated_fat: 3, sugar: 22 },
  { item: "Turkey sandwich",                 calories: 450, protein: 30, carbs: 42, fat: 16, fiber: 5,  saturated_fat: 4, sugar: 6 },
  { item: "Bean and veggie burrito",         calories: 560, protein: 22, carbs: 78, fat: 18, fiber: 14, saturated_fat: 6, sugar: 5 },
  { item: "Cottage cheese and berries",      calories: 220, protein: 24, carbs: 18, fat: 6,  fiber: 3,  saturated_fat: 3, sugar: 12 }
]

start_date = Date.current - 29
NutritionEntry.where(logged_on: start_date..Date.current).destroy_all

(start_date..Date.current).each do |day|
  # 3-4 items per day, deterministically varied by day-of-year (no RNG so re-seeding is stable).
  count = 3 + (day.yday % 2)
  count.times do |i|
    food = mock_foods[(day.yday + i) % mock_foods.size]
    NutritionEntry.create!(food.merge(logged_on: day, raw_input: "seed"))
  end
end

puts "Seeded nutrition entries for #{start_date} through #{Date.current} (#{NutritionEntry.where(logged_on: start_date..Date.current).count} entries)."
