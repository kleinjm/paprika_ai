# Schema Information
#
# Table name: ZBOOKMARK
#
#  Z_PK        :integer          primary key
#  Z_ENT       :integer
#  Z_OPT       :integer
#  ZISSYNCED   :integer
#  ZORDERFLAG  :integer
#  ZSTATUS     :string
#  ZTITLE      :string
#  ZUID        :string
#  ZURL        :string
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
