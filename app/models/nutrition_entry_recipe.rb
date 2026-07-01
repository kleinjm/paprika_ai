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
class NutritionEntryRecipe < ApplicationRecord
  belongs_to :nutrition_entry

  validates :recipe_id, presence: true,
                        uniqueness: { scope: :nutrition_entry_id }

  # The Paprika recipe lives in the read-only Paprika database, so it can't be a
  # real Active Record association across connections.
  def recipe
    Paprika::Recipe.find_by(Z_PK: recipe_id)
  end
end
