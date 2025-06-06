module Paprika
  class Recipe < ApplicationRecord
    self.table_name = "ZRECIPE"

    has_many :recipe_categories, class_name: "Paprika::RecipeCategory", foreign_key: "ZRECIPE"
    has_many :categories, through: :recipe_categories, class_name: "Paprika::Category"
    has_many :recipe_photos, class_name: "Paprika::RecipePhoto", foreign_key: "ZRECIPE"
    has_many :menu_items, class_name: "Paprika::MenuItem", foreign_key: "ZRECIPE"
    has_many :menus, through: :menu_items, class_name: "Paprika::Menu"
  end
end
