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
#  user_id       :bigint
#
# Indexes
#
#  index_nutrition_entries_on_logged_on  (logged_on)
#  index_nutrition_entries_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class NutritionEntry < ApplicationRecord
  belongs_to :user
  has_many :nutrition_entry_recipes, dependent: :destroy

  validates :item, presence: true
  validates :logged_on, presence: true

  scope :for_day, ->(date) { where(logged_on: date).order(:created_at) }

  # The matched Paprika recipes live in the read-only Paprika database, so they
  # are loaded manually rather than through an Active Record association.
  def recipes
    Paprika::Recipe.where(Z_PK: nutrition_entry_recipes.pluck(:recipe_id))
  end

  TOTALED_COLUMNS = %i[calories protein carbs fat fiber saturated_fat sugar].freeze

  def self.totals_for(date)
    sums = where(logged_on: date).pick(
      *TOTALED_COLUMNS.map { |col| Arel.sql("COALESCE(SUM(#{col}),0)") }
    )
    TOTALED_COLUMNS.zip(Array(sums)).to_h
  end

  # One row per logged day (most recent first) with its summed nutrients.
  def self.daily_totals
    rows = group(:logged_on).order(logged_on: :desc).pluck(
      Arel.sql("logged_on"),
      *TOTALED_COLUMNS.map { |col| Arel.sql("COALESCE(SUM(#{col}),0)") }
    )
    rows.map { |date, *sums| { date: date, totals: TOTALED_COLUMNS.zip(sums).to_h } }
  end
end
