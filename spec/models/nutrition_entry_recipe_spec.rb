require "rails_helper"

# == Schema Information
#
# Table name: nutrition_entry_recipes
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  nutrition_entry_id :bigint           not null
#  recipe_id          :integer          not null
#
# Indexes
#
#  index_entry_recipes_on_entry_and_recipe              (nutrition_entry_id,recipe_id) UNIQUE
#  index_nutrition_entry_recipes_on_nutrition_entry_id  (nutrition_entry_id)
#
# Foreign Keys
#
#  fk_rails_...  (nutrition_entry_id => nutrition_entries.id)
#
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
