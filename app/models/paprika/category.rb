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
module Paprika
  class Category < ApplicationRecord
    self.table_name = "Z_12CATEGORIES"

    has_many :recipe_categories, class_name: "Paprika::RecipeCategory", foreign_key: "Z_12CATEGORIES"
    has_many :recipes, through: :recipe_categories
  end
end
