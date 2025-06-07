# Schema Information
#
# Table name: ZGROCERYLIST
#
#  Z_PK            :integer          primary key
#  Z_ENT           :integer
#  Z_OPT           :integer
#  ZISDEFAULT      :integer
#  ZISSYNCED       :integer
#  ZORDERFLAG      :integer
#  ZNAME           :string
#  ZREMINDERSLIST  :string
#  ZSTATUS         :string
#  ZUID            :string
#
# Indexes
#
#  Z_GroceryList_byUidIndex  (ZUID)
#
module Paprika
  class GroceryList < ApplicationRecord
    self.table_name = "ZGROCERYLIST"
    has_many :grocery_items,
      class_name: "Paprika::GroceryItem",
      foreign_key: "ZLIST"
  end
end
