module Paprika
  class GroceryList < ApplicationRecord
    self.table_name = "ZGROCERYLIST"
    has_many :grocery_items, class_name: "Paprika::GroceryItem", foreign_key: "ZGROCERYLIST"
  end
end
