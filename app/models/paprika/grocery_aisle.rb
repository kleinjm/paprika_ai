# == Schema Information
#
# Table name: ZGROCERYAISLE
#
#  ZISSYNCED  :integer
#  ZNAME      :string
#  ZORDERFLAG :integer
#  ZSTATUS    :string
#  ZUID       :string
#  Z_ENT      :integer
#  Z_OPT      :integer
#  Z_PK       :integer          primary key
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
