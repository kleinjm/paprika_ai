require "rails_helper"

RSpec.describe ServingsSkill do
  describe ".format" do
    it "stamps the count and version date, pluralizing correctly" do
      expect(described_class.format(4)).to eq("4 servings (AI Generated - 7/8/26)")
      expect(described_class.format(1)).to eq("1 serving (AI Generated - 7/8/26)")
    end

    it "returns nil for a non-positive or blank count" do
      expect(described_class.format(0)).to be_nil
      expect(described_class.format(nil)).to be_nil
    end
  end

  describe ".write_enabled?" do
    it "follows the shared nutrition write-back toggle" do
      allow(NutritionSkill).to receive(:write_enabled?).and_return(false)
      expect(described_class.write_enabled?).to be(false)
    end
  end
end
