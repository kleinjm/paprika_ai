# == Schema Information
#
# Table name: ZRECIPE
#
#  ZCOOKTIME            :string
#  ZCREATED             :datetime
#  ZDESCRIPTIONTEXT     :string
#  ZDIFFICULTY          :string
#  ZDIRECTIONS          :string
#  ZIMAGEURL            :string
#  ZINGREDIENTS         :string
#  ZINTRASH             :integer
#  ZISPINNED            :integer
#  ZISSYNCED            :integer
#  ZNAME                :string
#  ZNOTES               :string
#  ZNUTRITIONALINFO     :string
#  ZONFAVORITES         :integer
#  ZPHOTO               :string
#  ZPHOTOHASH           :string
#  ZPHOTOISDOWNLOADED   :integer
#  ZPHOTOISUPLOADED     :integer
#  ZPHOTOLARGE          :string
#  ZPREPTIME            :string
#  ZRATING              :integer
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
#  Z_ENT                :integer
#  Z_OPT                :integer
#  Z_PK                 :integer          primary key
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
    attribute :nutritional_info, :string
    alias_attribute :nutritional_info, :ZNUTRITIONALINFO

    # Paprika marks trashed recipes with ZINTRASH = 1; live recipes are 0 (or NULL).
    scope :not_trashed, -> { where(ZINTRASH: [ nil, 0 ]) }
    scope :not_trashed_excluding, ->(ids) { not_trashed.where.not(Z_PK: ids).order(:ZNAME) }
    scope :not_trashed_in, ->(ids) { not_trashed.where(Z_PK: ids).order(:ZNAME) }

    # This is the join table for recipes and categories.
    has_many :categories, class_name: "Paprika::Category", foreign_key: "Z_12RECIPES"
    # This the actual categories for a recipe.
    has_many :recipe_categories, class_name: "Paprika::RecipeCategory", through: :categories

    has_many :recipe_photos, class_name: "Paprika::RecipePhoto", foreign_key: "ZRECIPE"
    has_many :menu_items, class_name: "Paprika::MenuItem", foreign_key: "ZRECIPE"
    has_many :menus, through: :menu_items, class_name: "Paprika::Menu"

    def to_ai_json
      {
        name: name,
        ingredients: ingredients,
        directions: directions,
        categories: recipe_categories.map(&:name)
      }
    end

    # Persist AI-computed batch macros into the Paprika nutrition field using the
    # writable connection. Writes via Z_PK so it works on read-only model instances.
    def update_nutritional_info!(text)
      Paprika::WritableApplicationRecord.connection.exec_update(
        ActiveRecord::Base.sanitize_sql(
          [ "UPDATE ZRECIPE SET ZNUTRITIONALINFO = ? WHERE Z_PK = ?", text, id ]
        ),
        "Paprika Nutrition Update"
      )
    end
  end
end
