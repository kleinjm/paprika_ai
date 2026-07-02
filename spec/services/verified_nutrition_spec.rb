require "rails_helper"

RSpec.describe VerifiedNutrition do
  let(:verified) do
    "Verified\nCalories: 298.4 kcal\nProtein: 23.5 g\nCarbohydrates: 32 g\n" \
    "Fat: 4.8 g\nFiber: 7 g\nSaturated Fat: 1.6 g\nSugar: 1.8 g"
  end

  describe ".verified?" do
    it "is true when the block starts with Verified" do
      expect(described_class.verified?(verified)).to be(true)
    end

    it "is false for other text or nil" do
      expect(described_class.verified?("Calories: 100")).to be(false)
      expect(described_class.verified?(nil)).to be(false)
    end
  end

  describe ".parse" do
    it "extracts each nutrient, distinguishing fat from saturated fat" do
      expect(described_class.parse(verified)).to eq(
        calories: 298.4, protein: 23.5, carbs: 32.0, fat: 4.8, fiber: 7.0, saturated_fat: 1.6, sugar: 1.8
      )
    end

    it "parses AI-generated blocks too" do
      ai = "Meal Total (AI Generated - 7/2/26)\nCalories: 2400 kcal\nProtein: 180 g\n" \
           "Carbohydrates: 120 g\nFat: 80 g\nFiber: 40 g\nSaturated Fat: 25 g\nSugar: 30 g"
      expect(described_class.parse(ai)).to include(calories: 2400.0, saturated_fat: 25.0, fat: 80.0)
    end
  end

  describe ".missing" do
    it "lists nutrients absent from the block" do
      partial = "Verified\nCalories: 300\nProtein: 20"
      expect(described_class.missing(partial)).to contain_exactly(:carbs, :fat, :fiber, :saturated_fat, :sugar)
    end
  end
end
