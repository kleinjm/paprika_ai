# == Schema Information
#
# Table name: ZMENUITEM
#
#  ZDAY       :integer
#  ZISSYNCED  :integer
#  ZMENU      :integer
#  ZNAME      :string
#  ZORDERFLAG :integer
#  ZRECIPE    :integer
#  ZSTATUS    :string
#  ZTYPE      :integer
#  ZUID       :string
#  Z_ENT      :integer
#  Z_OPT      :integer
#  Z_PK       :integer          primary key
#
# Indexes
#
#  ZMENUITEM_ZMENU_INDEX    (ZMENU)
#  ZMENUITEM_ZRECIPE_INDEX  (ZRECIPE)
#  ZMENUITEM_ZTYPE_INDEX    (ZTYPE)
#  Z_MenuItem_byUidIndex    (ZUID)
#
module Paprika
  class MenuItem < ApplicationRecord
    self.table_name = "ZMENUITEM"

    belongs_to :menu, class_name: "Paprika::Menu", foreign_key: "ZMENU"
    belongs_to :recipe, class_name: "Paprika::Recipe", foreign_key: "ZRECIPE"
  end
end
