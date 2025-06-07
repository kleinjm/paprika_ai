# Schema Information
#
# Table name: ZRECIPE
#
#  Z_PK                  :integer          primary key
#  Z_ENT                 :integer
#  Z_OPT                 :integer
#  ZINTRASH             :integer
#  ZISPINNED            :integer
#  ZISSYNCED            :integer
#  ZONFAVORITES         :integer
#  ZPHOTOISDOWNLOADED   :integer
#  ZPHOTOISUPLOADED     :integer
#  ZRATING              :integer
#  ZCREATED             :timestamp
#  ZCOOKTIME            :string
#  ZDESCRIPTIONTEXT     :string
#  ZDIFFICULTY          :string
#  ZDIRECTIONS          :string
#  ZIMAGEURL            :string
#  ZINGREDIENTS         :string
#  ZNAME                :string
#  ZNOTES               :string
#  ZNUTRITIONALINFO     :string
#  ZPHOTO               :string
#  ZPHOTOHASH           :string
#  ZPHOTOLARGE          :string
#  ZPREPTIME            :string
#  ZSCALE               :string
#  ZSELECTEDDIRECTION   :string
#  ZSELECTEDINGREDIENTS :string
#  ZSERVINGS            :string
#  ZSOURCE              :string
#  ZSOURCEURL           :string
#  ZSTATUS              :string
#  ZSYNCHASH            :string
#  ZTOTALTIME           :string
#  ZUID                 :string
#
# Indexes
#
#  Z_Recipe_byCreatedIndex  (ZCREATED)
#  Z_Recipe_byNameIndex     (ZNAME)
#  Z_Recipe_byRatingIndex   (ZRATING)
#  Z_Recipe_byUidIndex      (ZUID)
#
module Paprika
  class Recipe < ApplicationRecord
    self.table_name = "ZRECIPE"

    attribute :name, :string
    alias_attribute :name, :ZNAME
    attribute :ingredients, :string
    alias_attribute :ingredients, :ZINGREDIENTS
    attribute :directions, :string
    alias_attribute :directions, :ZDIRECTIONS

    # This is the join table for recipes and categories.
    has_many :categories, class_name: "Paprika::Category", foreign_key: "Z_12RECIPES"
    # This the actual categories for a recipe.
    has_many :recipe_categories, class_name: "Paprika::RecipeCategory", through: :categories

    has_many :recipe_photos, class_name: "Paprika::RecipePhoto", foreign_key: "ZRECIPE"
    has_many :menu_items, class_name: "Paprika::MenuItem", foreign_key: "ZRECIPE"
    has_many :menus, through: :menu_items, class_name: "Paprika::Menu"
  end
end
