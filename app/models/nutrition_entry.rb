class NutritionEntry < ApplicationRecord
  validates :item, presence: true
  validates :logged_on, presence: true

  scope :for_day, ->(date) { where(logged_on: date).order(:created_at) }

  def self.totals_for(date)
    where(logged_on: date).pick(
      Arel.sql("COALESCE(SUM(calories),0)"),
      Arel.sql("COALESCE(SUM(protein),0)"),
      Arel.sql("COALESCE(SUM(carbs),0)"),
      Arel.sql("COALESCE(SUM(fat),0)")
    ).then { |c, p, cb, f| { calories: c, protein: p, carbs: cb, fat: f } }
  end
end
