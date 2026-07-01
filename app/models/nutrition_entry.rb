# == Schema Information
#
# Table name: nutrition_entries
#
#  id           :bigint           not null, primary key
#  calories     :integer
#  carbs        :decimal(6, 1)
#  fat          :decimal(6, 1)
#  item         :string           not null
#  logged_on    :date             not null
#  protein      :decimal(6, 1)
#  raw_input    :text
#  recipe_match :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_nutrition_entries_on_logged_on  (logged_on)
#
class NutritionEntry < ApplicationRecord
  has_many :nutrition_entry_recipes, dependent: :destroy

  validates :item, presence: true
  validates :logged_on, presence: true

  scope :for_day, ->(date) { where(logged_on: date).order(:created_at) }

  # The matched Paprika recipes live in the read-only Paprika database, so they
  # are loaded manually rather than through an Active Record association.
  def recipes
    Paprika::Recipe.where(Z_PK: nutrition_entry_recipes.pluck(:recipe_id))
  end

  def self.totals_for(date)
    where(logged_on: date).pick(
      Arel.sql("COALESCE(SUM(calories),0)"),
      Arel.sql("COALESCE(SUM(protein),0)"),
      Arel.sql("COALESCE(SUM(carbs),0)"),
      Arel.sql("COALESCE(SUM(fat),0)")
    ).then { |c, p, cb, f| { calories: c, protein: p, carbs: cb, fat: f } }
  end
end
