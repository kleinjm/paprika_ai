module Paprika
  class GroceryAisle < ApplicationRecord
    self.table_name = "ZGROCERYAISLE"
    has_many :grocery_items, class_name: "Paprika::GroceryItem", foreign_key: "ZGROCERYAISLE"
  end
end
