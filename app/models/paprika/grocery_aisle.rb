# Schema Information
#
# Table name: ZGROCERYAISLE
#
#  Z_PK        :integer          primary key
#  Z_ENT       :integer
#  Z_OPT       :integer
#  ZISSYNCED   :integer
#  ZORDERFLAG  :integer
#  ZNAME       :string
#  ZSTATUS     :string
#  ZUID        :string
#
# Indexes
#
#  Z_GroceryAisle_byUidIndex  (ZUID)
#
module Paprika
  class GroceryAisle < ApplicationRecord
    self.table_name = "ZGROCERYAISLE"
    has_many :grocery_items, class_name: "Paprika::GroceryItem", foreign_key: "ZGROCERYAISLE"
  end
end
