require "rails_helper"

RSpec.describe NutritionSkill do
  let(:batch) { { "calories" => 2400, "protein" => 180, "carbs" => 120, "fat" => 80 } }

  describe ".header" do
    it "stamps the version date into the header" do
      expect(described_class.header).to eq("Meal Total (AI Generated - 7/1/26)")
    end
  end

  describe ".format" do
    it "renders the dated header followed by the batch macros" do
      expect(described_class.format(batch)).to eq(
        "Meal Total (AI Generated - 7/1/26)\n" \
        "Calories: 2400 kcal\nProtein: 180 g\nCarbohydrates: 120 g\nFat: 80 g"
      )
    end
  end

  describe ".write_enabled?" do
    it "defaults to read-write" do
      expect(described_class.write_enabled?).to be(true)
    end

    it "is false in read-only mode" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("NUTRITION_WRITEBACK", "read_write").and_return("read_only")

      expect(described_class.write_enabled?).to be(false)
    end
  end
end
