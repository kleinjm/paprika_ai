module Paprika
  # Local mirror of a Paprika recipe (table "ZRECIPE", keyed by Z_PK). Populated
  # from the Paprika cloud via `paprika:pull`. Nutrition edits are written back
  # to the cloud through PaprikaCloud.
  class Recipe < ApplicationRecord
    self.table_name = "ZRECIPE"

    alias_attribute :uid, :ZUID
    alias_attribute :name, :ZNAME
    alias_attribute :ingredients, :ZINGREDIENTS
    alias_attribute :directions, :ZDIRECTIONS
    alias_attribute :nutritional_info, :ZNUTRITIONALINFO

    # Paprika marks trashed recipes with ZINTRASH = 1; live recipes are 0 (or NULL).
    scope :not_trashed, -> { where(ZINTRASH: [ nil, 0 ]) }
    scope :not_trashed_excluding, ->(ids) { not_trashed.where.not(Z_PK: ids).order(:ZNAME) }
    scope :not_trashed_in, ->(ids) { not_trashed.where(Z_PK: ids).order(:ZNAME) }

    # This is the join table for recipes and categories.
    has_many :categories, class_name: "Paprika::Category", foreign_key: "Z_12RECIPES"
    # This the actual categories for a recipe.
    has_many :recipe_categories, class_name: "Paprika::RecipeCategory", through: :categories

    def to_ai_json
      {
        name: name,
        ingredients: ingredients,
        directions: directions,
        categories: recipe_categories.map(&:name)
      }
    end

    # Persist AI-computed batch macros: update the local mirror and write the
    # value back to the Paprika cloud so it syncs to all devices.
    def update_nutritional_info!(text)
      update!(ZNUTRITIONALINFO: text)
      PaprikaCloud.push_nutritional_info(uid: uid, text: text)
    end
  end
end
