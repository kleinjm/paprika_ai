# == Schema Information
#
# Table name: ZMENU
#
#  ZDAYS      :integer
#  ZISSYNCED  :integer
#  ZNAME      :string
#  ZNOTES     :string
#  ZORDERFLAG :integer
#  ZSTATUS    :string
#  ZUID       :string
#  Z_ENT      :integer
#  Z_OPT      :integer
#  Z_PK       :integer          primary key
#
# Indexes
#
#  Z_Menu_byUidIndex  (ZUID)
#
module Paprika
  class Menu < ApplicationRecord
    self.table_name = "ZMENU"

    has_many :menu_items, class_name: "Paprika::MenuItem", foreign_key: "ZMENU"
    has_many :recipes, through: :menu_items
  end
end
