# Schema Information
#
# Table name: ZPANTRYITEM
#
#  Z_PK              :integer          primary key
#  Z_ENT             :integer
#  Z_OPT             :integer
#  ZHASEXPIRATION    :integer
#  ZINSTOCK          :integer
#  ZISSYNCED         :integer
#  ZAISLE            :integer
#  ZEXPIRATIONDATE   :timestamp
#  ZPURCHASEDATE     :timestamp
#  ZAISLENAME        :string
#  ZINGREDIENT       :string
#  ZQUANTITY         :string
#  ZSTATUS           :string
#  ZUID              :string
#
# Indexes
#
#  Z_PantryItem_byUidIndex  (ZUID)
#  ZPANTRYITEM_ZAISLE_INDEX (ZAISLE)
#
module Paprika
  class PantryItem < ApplicationRecord
    self.table_name = "ZPANTRYITEM"
  end
end
