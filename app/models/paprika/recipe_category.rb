# Schema Information
#
# Table name: ZRECIPECATEGORY
#
#  Z_PK        :integer          primary key
#  Z_ENT       :integer
#  Z_OPT       :integer
#  ZISSYNCED   :integer
#  ZORDERFLAG  :integer
#  ZPARENT     :integer
#  ZNAME       :string
#  ZSTATUS     :string
#  ZUID        :string
#
# Indexes
#
#  Z_RecipeCategory_byUidIndex  (ZUID)
#  ZRECIPECATEGORY_ZPARENT_INDEX (ZPARENT)
#

# This table is the actual category for a recipe.
module Paprika
  class RecipeCategory < ApplicationRecord
    self.table_name = "ZRECIPECATEGORY"

    attribute :name, :string
    alias_attribute :name, :ZNAME

    has_many :categories, class_name: "Paprika::Category", foreign_key: "Z_12CATEGORIES"
    has_many :recipes, through: :categories, class_name: "Paprika::Recipe"
  end
end
