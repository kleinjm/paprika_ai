# This table is the actual category for a recipe.
# == Schema Information
#
# Table name: ZRECIPECATEGORY
#
#  ZISSYNCED  :integer
#  ZNAME      :string
#  ZORDERFLAG :integer
#  ZPARENT    :integer
#  ZSTATUS    :string
#  ZUID       :string
#  Z_ENT      :integer
#  Z_OPT      :integer
#  Z_PK       :integer          primary key
#
# Indexes
#
#  ZRECIPECATEGORY_ZPARENT_INDEX  (ZPARENT)
#  Z_RecipeCategory_byUidIndex    (ZUID)
#
module Paprika
  class RecipeCategory < ApplicationRecord
    self.table_name = "ZRECIPECATEGORY"

    alias_attribute :name, :ZNAME

    has_many :categories, class_name: "Paprika::Category", foreign_key: "Z_12CATEGORIES"
    has_many :recipes, through: :categories, class_name: "Paprika::Recipe"
  end
end
