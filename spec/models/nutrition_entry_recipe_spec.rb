require "rails_helper"

RSpec.describe NutritionEntryRecipe do
  let(:entry) { NutritionEntry.create!(logged_on: Date.current, item: "chili") }

  describe "validations" do
    it "requires a recipe_id" do
      record = described_class.new(nutrition_entry: entry)
      expect(record).not_to be_valid
      expect(record.errors[:recipe_id]).not_to be_empty
    end

    it "is unique per recipe within an entry" do
      entry.nutrition_entry_recipes.create!(recipe_id: 42)
      dup = entry.nutrition_entry_recipes.build(recipe_id: 42)
      expect(dup).not_to be_valid
    end
  end

  describe "#recipe" do
    it "looks up the Paprika recipe by Z_PK" do
      record = entry.nutrition_entry_recipes.create!(recipe_id: 42)
      recipe = double("Recipe")
      expect(Paprika::Recipe).to receive(:find_by).with(Z_PK: 42).and_return(recipe)

      expect(record.recipe).to eq(recipe)
    end
  end
end
