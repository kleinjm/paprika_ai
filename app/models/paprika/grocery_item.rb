module Paprika
  class GroceryItem < ApplicationRecord
    self.table_name = "ZGROCERYITEM"
    belongs_to :grocery_list, class_name: "Paprika::GroceryList", foreign_key: "ZGROCERYLIST"
    belongs_to :grocery_aisle, class_name: "Paprika::GroceryAisle", foreign_key: "ZGROCERYAISLE", optional: true
  end
end
