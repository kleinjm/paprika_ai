# == Schema Information
#
# Table name: ZSYNCSTATUS
#
#  ZNAME     :string
#  ZREVISION :integer
#  Z_ENT     :integer
#  Z_OPT     :integer
#  Z_PK      :integer          primary key
#
module Paprika
  class SyncStatus < ApplicationRecord
    self.table_name = "ZSYNCSTATUS"
  end
end
