# Schema Information
#
# Table name: ZMEAL
#
#  Z_PK            :integer          primary key
#  Z_ENT           :integer
#  Z_OPT           :integer
#  ZISSYNCED       :integer
#  ZORDERFLAG      :integer
#  ZORIGINALTYPE   :integer
#  ZRECIPE         :integer
#  ZTYPE           :integer
#  ZDATE           :timestamp
#  ZNAME           :string
#  ZSTATUS         :string
#  ZUID            :string
#
# Indexes
#
#  Z_Meal_byDateIndex  (ZDATE)
#  Z_Meal_byUidIndex   (ZUID)
#  ZMEAL_ZRECIPE_INDEX (ZRECIPE)
#  ZMEAL_ZTYPE_INDEX   (ZTYPE)
#
module Paprika
  class Meal < ApplicationRecord
    self.table_name = "ZMEAL"
    belongs_to :meal_type, class_name: "Paprika::MealType", foreign_key: "ZMEALTYPE", optional: true
  end
end
