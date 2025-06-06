module Paprika
  class MenuItem < ApplicationRecord
    self.table_name = "ZMENUITEM"

    belongs_to :menu, class_name: "Paprika::Menu", foreign_key: "ZMENU"
    belongs_to :recipe, class_name: "Paprika::Recipe", foreign_key: "ZRECIPE"
  end
end
