# Schema Information
#
# Table name: ZRECIPEPHOTO
#
#  Z_PK                  :integer          primary key
#  Z_ENT                 :integer
#  Z_OPT                 :integer
#  ZISDOWNLOADERRORED    :integer
#  ZISDOWNLOADED         :integer
#  ZISPENDINGDELETION    :integer
#  ZISSYNCED             :integer
#  ZISUPLOADED           :integer
#  ZORDERFLAG            :integer
#  ZRECIPE               :integer
#  ZDOWNLOADERRORMESSAGE :string
#  ZFILENAME             :string
#  ZNAME                 :string
#  ZPHOTOHASH            :string
#  ZRECIPEUID            :string
#  ZSTATUS               :string
#  ZUID                  :string
#
# Indexes
#
#  Z_RecipePhoto_byUidIndex  (ZUID)
#  ZRECIPEPHOTO_ZRECIPE_INDEX (ZRECIPE)
#
module Paprika
  class RecipePhoto < ApplicationRecord
    self.table_name = "ZRECIPEPHOTO"
    belongs_to :recipe, class_name: "Paprika::Recipe", foreign_key: "ZRECIPE"
  end
end
