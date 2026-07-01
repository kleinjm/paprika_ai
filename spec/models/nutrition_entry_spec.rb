require "rails_helper"

# == Schema Information
#
# Table name: nutrition_entries
#
#  id            :bigint           not null, primary key
#  calories      :integer
#  carbs         :decimal(6, 1)
#  fat           :decimal(6, 1)
#  fiber         :decimal(6, 1)
#  item          :string           not null
#  logged_on     :date             not null
#  protein       :decimal(6, 1)
#  raw_input     :text
#  recipe_match  :string
#  saturated_fat :decimal(6, 1)
#  sugar         :decimal(6, 1)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_nutrition_entries_on_logged_on  (logged_on)
#
RSpec.describe NutritionEntry do
  describe "validations" do
    it "requires an item and a logged_on date" do
      entry = described_class.new
      expect(entry).not_to be_valid
      expect(entry.errors[:item]).not_to be_empty
      expect(entry.errors[:logged_on]).not_to be_empty
    end
  end

  describe "#recipes" do
    it "loads the linked Paprika recipes by their ids" do
      entry = described_class.create!(logged_on: Date.current, item: "chili")
      entry.nutrition_entry_recipes.create!(recipe_id: 42)
      entry.nutrition_entry_recipes.create!(recipe_id: 7)

      relation = double("Relation")
      expect(Paprika::Recipe).to receive(:where).with(Z_PK: [ 42, 7 ]).and_return(relation)

      expect(entry.recipes).to eq(relation)
    end
  end

  describe ".for_day" do
    it "returns only entries logged on the given date, oldest first" do
      today = Date.new(2026, 6, 29)
      a = described_class.create!(logged_on: today, item: "eggs", calories: 150)
      described_class.create!(logged_on: today - 1, item: "old", calories: 99)
      b = described_class.create!(logged_on: today, item: "banana", calories: 100)

      expect(described_class.for_day(today)).to eq([a, b])
    end
  end

  describe ".totals_for" do
    it "sums each nutrient across the day" do
      day = Date.new(2026, 6, 29)
      described_class.create!(logged_on: day, item: "a", calories: 600, protein: 45, carbs: 30, fat: 20,
                              fiber: 8, saturated_fat: 5, sugar: 4)
      described_class.create!(logged_on: day, item: "b", calories: 150, protein: 12, carbs: 1, fat: 10,
                              fiber: 2, saturated_fat: 3, sugar: 1)
      described_class.create!(logged_on: day - 1, item: "other", calories: 999, protein: 99)

      totals = described_class.totals_for(day)

      expect(totals[:calories]).to eq(750)
      expect(totals[:protein]).to eq(57)
      expect(totals[:carbs]).to eq(31)
      expect(totals[:fat]).to eq(30)
      expect(totals[:fiber]).to eq(10)
      expect(totals[:saturated_fat]).to eq(8)
      expect(totals[:sugar]).to eq(5)
    end

    it "returns zeros when nothing is logged" do
      expect(described_class.totals_for(Date.new(2026, 1, 1))).to eq(
        calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, saturated_fat: 0, sugar: 0
      )
    end
  end
end
