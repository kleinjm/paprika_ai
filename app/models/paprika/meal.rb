module Paprika
  class Meal < ApplicationRecord
    self.table_name = "ZMEAL"
    belongs_to :meal_type, class_name: "Paprika::MealType", foreign_key: "ZMEALTYPE", optional: true
  end
end
