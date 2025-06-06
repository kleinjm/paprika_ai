module Paprika
  class RecipeCategory < ApplicationRecord
    self.table_name = "ZRECIPECATEGORY"

    belongs_to :recipe, class_name: "Paprika::Recipe", foreign_key: "ZRECIPE"
    belongs_to :category, class_name: "Paprika::Category", foreign_key: "Z_12CATEGORIES"
  end
end
