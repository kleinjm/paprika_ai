# == Schema Information
#
# Table name: ZRECIPEPHOTO
#
#  ZDOWNLOADERRORMESSAGE :string
#  ZFILENAME             :string
#  ZISDOWNLOADED         :integer
#  ZISDOWNLOADERRORED    :integer
#  ZISPENDINGDELETION    :integer
#  ZISSYNCED             :integer
#  ZISUPLOADED           :integer
#  ZNAME                 :string
#  ZORDERFLAG            :integer
#  ZPHOTOHASH            :string
#  ZRECIPE               :integer
#  ZRECIPEUID            :string
#  ZSTATUS               :string
#  ZUID                  :string
#  Z_ENT                 :integer
#  Z_OPT                 :integer
#  Z_PK                  :integer          primary key
#
# Indexes
#
#  ZRECIPEPHOTO_ZRECIPE_INDEX  (ZRECIPE)
#  Z_RecipePhoto_byUidIndex    (ZUID)
#
module Paprika
  class RecipePhoto < ApplicationRecord
    self.table_name = "ZRECIPEPHOTO"
    belongs_to :recipe, class_name: "Paprika::Recipe", foreign_key: "ZRECIPE"
  end
end
