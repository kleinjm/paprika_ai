# Schema Information
#
# Table name: ZMENU
#
#  Z_PK        :integer          primary key
#  Z_ENT       :integer
#  Z_OPT       :integer
#  ZDAYS       :integer
#  ZISSYNCED   :integer
#  ZORDERFLAG  :integer
#  ZNAME       :string
#  ZNOTES      :string
#  ZSTATUS     :string
#  ZUID        :string
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
