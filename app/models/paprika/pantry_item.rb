# == Schema Information
#
# Table name: ZPANTRYITEM
#
#  ZAISLE          :integer
#  ZAISLENAME      :string
#  ZEXPIRATIONDATE :datetime
#  ZHASEXPIRATION  :integer
#  ZINGREDIENT     :string
#  ZINSTOCK        :integer
#  ZISSYNCED       :integer
#  ZPURCHASEDATE   :datetime
#  ZQUANTITY       :string
#  ZSTATUS         :string
#  ZUID            :string
#  Z_ENT           :integer
#  Z_OPT           :integer
#  Z_PK            :integer          primary key
#
# Indexes
#
#  ZPANTRYITEM_ZAISLE_INDEX  (ZAISLE)
#  Z_PantryItem_byUidIndex   (ZUID)
#
module Paprika
  class PantryItem < ApplicationRecord
    self.table_name = "ZPANTRYITEM"
  end
end
