module Paprika
  class MealType < ApplicationRecord
    self.table_name = "ZMEALTYPE"
    has_many :meals, class_name: "Paprika::Meal", foreign_key: "ZMEALTYPE"
  end
end
