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
module Paprika
  class RecipeCategory < ApplicationRecord
    self.table_name = "ZRECIPECATEGORY"

    belongs_to :recipe, class_name: "Paprika::Recipe", foreign_key: "ZRECIPE"
    belongs_to :category, class_name: "Paprika::Category", foreign_key: "Z_12CATEGORIES"
  end
end
