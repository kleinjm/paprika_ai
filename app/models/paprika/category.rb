module Paprika
  class Category < ApplicationRecord
    self.table_name = "Z_12CATEGORIES"

    has_many :recipe_categories, class_name: "Paprika::RecipeCategory", foreign_key: "Z_12CATEGORIES"
    has_many :recipes, through: :recipe_categories
  end
end
