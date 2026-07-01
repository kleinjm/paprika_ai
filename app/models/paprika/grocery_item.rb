# == Schema Information
#
# Table name: ZGROCERYITEM
#
#  ZAISLE       :integer
#  ZAISLENAME   :string
#  ZINGREDIENT  :string
#  ZINSTRUCTION :string
#  ZISSYNCED    :integer
#  ZLIST        :integer
#  ZNAME        :string
#  ZORDERFLAG   :integer
#  ZPURCHASED   :integer
#  ZQUANTITY    :string
#  ZRECIPENAME  :string
#  ZSEPARATE    :integer
#  ZSTATUS      :string
#  ZUID         :string
#  Z_ENT        :integer
#  Z_OPT        :integer
#  Z_PK         :integer          primary key
#
# Indexes
#
#  ZGROCERYITEM_ZAISLE_INDEX  (ZAISLE)
#  ZGROCERYITEM_ZLIST_INDEX   (ZLIST)
#  Z_GroceryItem_byUidIndex   (ZUID)
#
module Paprika
  class GroceryItem < ApplicationRecord
    self.table_name = "ZGROCERYITEM"

    attribute :name, :string
    alias_attribute :name, :ZNAME
    attribute :quantity, :string
    alias_attribute :quantity, :ZQUANTITY
    alias_attribute :purchased, :ZPURCHASED
    alias_attribute :separated, :ZSEPARATE
    alias_attribute :aisle, :ZAISLE
    alias_attribute :aisle_name, :ZAISLENAME
    alias_attribute :instruction, :ZINSTRUCTION
    alias_attribute :recipe_name, :ZRECIPENAME
    alias_attribute :status, :ZSTATUS
    alias_attribute :synced, :ZISSYNCED
    alias_attribute :order_flag, :ZORDERFLAG
    alias_attribute :uid, :ZUID
    alias_attribute :ingredient, :ZINGREDIENT

    belongs_to :grocery_list,
      class_name: "Paprika::GroceryList",
      foreign_key: "ZLIST"
    belongs_to :grocery_aisle,
      class_name: "Paprika::GroceryAisle",
      foreign_key: "ZAISLE",
      optional: true

    scope :purchased, -> { where(ZPURCHASED: 1) }
    scope :unpurchased, -> { where(ZPURCHASED: 0) }
  end
end
