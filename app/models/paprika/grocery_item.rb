# Schema Information
#
# Table name: ZGROCERYITEM
#
#  Z_PK          :integer          primary key
#  Z_ENT         :integer
#  Z_OPT         :integer
#  ZISSYNCED     :integer
#  ZORDERFLAG    :integer
#  ZPURCHASED    :integer
#  ZSEPARATE     :integer
#  ZAISLE        :integer
#  ZLIST         :integer
#  ZAISLENAME    :string
#  ZINGREDIENT   :string
#  ZINSTRUCTION  :string
#  ZNAME         :string
#  ZQUANTITY     :string
#  ZRECIPENAME   :string
#  ZSTATUS       :string
#  ZUID          :string
#
# Indexes
#
#  Z_GroceryItem_byUidIndex  (ZUID)
#  ZGROCERYITEM_ZAISLE_INDEX (ZAISLE)
#  ZGROCERYITEM_ZLIST_INDEX  (ZLIST)
#
module Paprika
  class GroceryItem < ApplicationRecord
    self.table_name = "ZGROCERYITEM"
    belongs_to :grocery_list, class_name: "Paprika::GroceryList", foreign_key: "ZGROCERYLIST"
    belongs_to :grocery_aisle, class_name: "Paprika::GroceryAisle", foreign_key: "ZGROCERYAISLE", optional: true
  end
end
