# Schema Information
#
# Table name: ZMEALTYPE
#
#  Z_PK            :integer          primary key
#  Z_ENT           :integer
#  Z_OPT           :integer
#  ZEXPORTALLDAY   :integer
#  ZISSYNCED       :integer
#  ZORDERFLAG      :integer
#  ZORIGINALTYPE   :integer
#  ZEXPORTTIME     :float
#  ZLASTUSED       :timestamp
#  ZCOLOR          :string
#  ZNAME           :string
#  ZSTATUS         :string
#  ZUID            :string
#
# Indexes
#
#  Z_MealType_byUidIndex  (ZUID)
#
module Paprika
  class MealType < ApplicationRecord
    self.table_name = "ZMEALTYPE"
    has_many :meals, class_name: "Paprika::Meal", foreign_key: "ZMEALTYPE"
  end
end
