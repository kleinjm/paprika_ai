# == Schema Information
#
# Table name: ZGROCERYLIST
#
#  ZISDEFAULT     :integer
#  ZISSYNCED      :integer
#  ZNAME          :string
#  ZORDERFLAG     :integer
#  ZREMINDERSLIST :string
#  ZSTATUS        :string
#  ZUID           :string
#  Z_ENT          :integer
#  Z_OPT          :integer
#  Z_PK           :integer          primary key
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
