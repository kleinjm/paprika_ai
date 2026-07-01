# == Schema Information
#
# Table name: ZMEALTYPE
#
#  ZCOLOR        :string
#  ZEXPORTALLDAY :integer
#  ZEXPORTTIME   :float
#  ZISSYNCED     :integer
#  ZLASTUSED     :datetime
#  ZNAME         :string
#  ZORDERFLAG    :integer
#  ZORIGINALTYPE :integer
#  ZSTATUS       :string
#  ZUID          :string
#  Z_ENT         :integer
#  Z_OPT         :integer
#  Z_PK          :integer          primary key
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
