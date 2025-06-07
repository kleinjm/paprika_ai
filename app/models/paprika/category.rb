# Schema Information
#
# Table name: Z_12CATEGORIES
#
#  Z_12RECIPES    :integer
#  Z_13CATEGORIES :integer
#
# Indexes
#
#  Z_12CATEGORIES_Z_13CATEGORIES_INDEX  (Z_13CATEGORIES, Z_12RECIPES)
#

# This table is the join table for recipes and categories.
module Paprika
  class Category < ApplicationRecord
    self.table_name = "Z_12CATEGORIES"

    belongs_to :recipe_category, class_name: "Paprika::RecipeCategory", foreign_key: "Z_13CATEGORIES"
    belongs_to :recipe, class_name: "Paprika::Recipe", foreign_key: "Z_12RECIPES"
  end
end
