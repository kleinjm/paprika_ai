module Paprika
  class RecipePhoto < ApplicationRecord
    self.table_name = "ZRECIPEPHOTO"
    belongs_to :recipe, class_name: "Paprika::Recipe", foreign_key: "ZRECIPE"
  end
end
