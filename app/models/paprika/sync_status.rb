# Schema Information
#
# Table name: ZSYNCSTATUS
#
#  Z_PK       :integer          primary key
#  Z_ENT      :integer
#  Z_OPT      :integer
#  ZREVISION  :integer
#  ZNAME      :string
#
module Paprika
  class SyncStatus < ApplicationRecord
    self.table_name = "ZSYNCSTATUS"
  end
end
