# == Schema Information
#
# Table name: ZBOOKMARK
#
#  ZISSYNCED  :integer
#  ZORDERFLAG :integer
#  ZSTATUS    :string
#  ZTITLE     :string
#  ZUID       :string
#  ZURL       :string
#  Z_ENT      :integer
#  Z_OPT      :integer
#  Z_PK       :integer          primary key
#
# Indexes
#
#  Z_Bookmark_byUidIndex  (ZUID)
#
module Paprika
  class Bookmark < ApplicationRecord
    self.table_name = "ZBOOKMARK"
  end
end
