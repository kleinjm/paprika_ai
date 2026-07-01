# == Schema Information
#
# Table name: ZMEAL
#
#  ZDATE         :datetime
#  ZISSYNCED     :integer
#  ZNAME         :string
#  ZORDERFLAG    :integer
#  ZORIGINALTYPE :integer
#  ZRECIPE       :integer
#  ZSTATUS       :string
#  ZTYPE         :integer
#  ZUID          :string
#  Z_ENT         :integer
#  Z_OPT         :integer
#  Z_PK          :integer          primary key
#
# Indexes
#
#  ZMEAL_ZRECIPE_INDEX  (ZRECIPE)
#  ZMEAL_ZTYPE_INDEX    (ZTYPE)
#  Z_Meal_byDateIndex   (ZDATE)
#  Z_Meal_byUidIndex    (ZUID)
#
module Paprika
  class Meal < ApplicationRecord
    self.table_name = "ZMEAL"
    belongs_to :meal_type, class_name: "Paprika::MealType", foreign_key: "ZMEALTYPE", optional: true
  end
end
