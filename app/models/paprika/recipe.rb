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
    # Free-text yield/serving count as entered in Paprika, e.g. "Serves 4",
    # "Yield: 12", or just "4". Often blank. Used to anchor portion estimates.
    alias_attribute :servings, :ZSERVINGS
    # The user's own Paprika-hosted photo (a signed S3 URL, refreshed each sync).
    alias_attribute :photo_url, :ZPHOTOURL
    # The original source image from the recipe's website. More stable than the
    # signed photo URL, so it's the fallback when there's no personal photo.
    alias_attribute :image_url, :ZIMAGEURL

    # Best available image for display. The Paprika photo URL is a *signed,
    # time-limited* S3 link — once its Expires timestamp passes, S3 returns 403 —
    # so we only use it while still valid and otherwise fall back to the original
    # source image, which is a stable public URL. nil when there's no usable
    # image at all.
    def display_image_url
      fresh_photo_url || image_url.presence
    end

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

    # Persist AI-computed batch macros. The cloud is the source of truth, so we
    # push there first; only if that succeeds do we refresh the local cache so
    # the UI reflects the change before the next full sync.
    def update_nutritional_info!(text)
      PaprikaCloud.push_nutritional_info(uid: uid, text: text)
      refresh_cache!(ZNUTRITIONALINFO: text)
    end

    # Persist rewritten (shorthand) directions. Cloud first, then cache refresh.
    def update_directions!(text)
      PaprikaCloud.push_directions(uid: uid, text: text)
      refresh_cache!(ZDIRECTIONS: text)
    end

    # Persist an AI-estimated serving count. Cloud first, then cache refresh.
    def update_servings!(text)
      PaprikaCloud.push_servings(uid: uid, text: text)
      refresh_cache!(ZSERVINGS: text)
    end

    private

    # The user's Paprika photo only if its signed URL hasn't expired yet.
    def fresh_photo_url
      return if photo_url.blank?

      photo_url unless signed_url_expired?(photo_url)
    end

    # True when a signed S3 URL carries an Expires timestamp already in the past.
    def signed_url_expired?(url)
      expires = url[/[?&]Expires=(\d+)/, 1]
      expires.present? && expires.to_i < Time.now.to_i
    end

    # Update the read-only mirror to match what we just wrote to the cloud.
    def refresh_cache!(attrs)
      self.class.syncing { update!(attrs) }
    end
  end
end
