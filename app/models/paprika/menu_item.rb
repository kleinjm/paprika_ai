# Schema Information
#
# Table name: ZMENUITEM
#
#  Z_PK        :integer          primary key
#  Z_ENT       :integer
#  Z_OPT       :integer
#  ZDAY        :integer
#  ZISSYNCED   :integer
#  ZORDERFLAG  :integer
#  ZMENU       :integer
#  ZRECIPE     :integer
#  ZTYPE       :integer
#  ZNAME       :string
#  ZSTATUS     :string
#  ZUID        :string
#
# Indexes
#
#  Z_MenuItem_byUidIndex  (ZUID)
#  ZMENUITEM_ZMENU_INDEX  (ZMENU)
#  ZMENUITEM_ZRECIPE_INDEX (ZRECIPE)
#  ZMENUITEM_ZTYPE_INDEX  (ZTYPE)

module Paprika
  class MenuItem < ApplicationRecord
    self.table_name = "ZMENUITEM"

    belongs_to :menu, class_name: "Paprika::Menu", foreign_key: "ZMENU"
    belongs_to :recipe, class_name: "Paprika::Recipe", foreign_key: "ZRECIPE"
  end
end
