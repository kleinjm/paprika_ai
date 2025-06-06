module Paprika
  class Menu < ApplicationRecord
    self.table_name = "ZMENU"

    has_many :menu_items, class_name: "Paprika::MenuItem", foreign_key: "ZMENU"
    has_many :recipes, through: :menu_items
  end
end
