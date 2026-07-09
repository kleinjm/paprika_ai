require "rails_helper"

RSpec.describe VerifiedServings do
  describe ".verified?" do
    it "is true only when the value starts with 'Verified'" do
      expect(described_class.verified?("Verified 4 servings")).to be(true)
      expect(described_class.verified?("verified: 6")).to be(true)
      expect(described_class.verified?("Serves 4")).to be(false)
      expect(described_class.verified?(nil)).to be(false)
    end
  end

  describe ".ai_generated?" do
    it "is true when the value carries the AI Generated marker" do
      expect(described_class.ai_generated?(ServingsSkill.format(4))).to be(true)
      expect(described_class.ai_generated?("Serves 4")).to be(false)
    end
  end

  describe ".writable?" do
    it "overwrites anything that isn't hand-verified" do
      expect(described_class.writable?("")).to be(true)
      expect(described_class.writable?(nil)).to be(true)
      expect(described_class.writable?("Serves 4")).to be(true)          # existing free text
      expect(described_class.writable?("Calories: 490 kcal")).to be(true) # garbage
      expect(described_class.writable?(ServingsSkill.format(8))).to be(true) # prior AI value
    end

    it "never overwrites a hand-verified value" do
      expect(described_class.writable?("Verified 4 servings")).to be(false)
    end
  end

  describe ".count" do
    it "best-effort parses the first integer, ignoring surrounding text" do
      expect(described_class.count("Serves 4")).to eq(4)
      expect(described_class.count("Yield: 12")).to eq(12)
      expect(described_class.count("3-4")).to eq(3)
      expect(described_class.count("8 (1 cup) servings")).to eq(8)
      expect(described_class.count("Verified 4 servings")).to eq(4)
      expect(described_class.count("")).to be_nil
    end
  end
end
