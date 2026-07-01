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

    # Paprika stores ZDATE as a Core Data (Cocoa) timestamp: seconds since
    # 2001-01-01, pinned to local midnight of the scheduled day.
    COCOA_EPOCH_OFFSET = 978_307_200

    alias_attribute :title, :ZNAME

    # Meals scheduled within an inclusive range of calendar dates.
    scope :scheduled_between, ->(start_date, end_date) {
      lower = Time.local(start_date.year, start_date.month, start_date.day).to_i - COCOA_EPOCH_OFFSET
      upper = Time.local(end_date.year, end_date.month, end_date.day).to_i + 1.day.to_i - COCOA_EPOCH_OFFSET
      where(ZDATE: lower...upper).order(:ZDATE)
    }

    def scheduled_on
      Time.at(self[:ZDATE] + COCOA_EPOCH_OFFSET).to_date
    end
  end
end
