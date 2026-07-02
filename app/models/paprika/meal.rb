module Paprika
  # Local mirror of a Paprika scheduled meal (table "paprika_meals"). Populated
  # from the Paprika cloud via `paprika:pull`. Linked to a recipe by its uid.
  class Meal < ApplicationRecord
    self.table_name = "paprika_meals"

    alias_attribute :title, :name

    # Meals scheduled within an inclusive range of calendar dates.
    scope :scheduled_between, ->(start_date, end_date) {
      where(scheduled_date: start_date..end_date).order(:scheduled_date)
    }

    def scheduled_on
      scheduled_date
    end

    # The recipe this meal references, if any (looked up by Paprika uid).
    def recipe
      return if recipe_uid.blank?

      Paprika::Recipe.find_by(ZUID: recipe_uid)
    end
  end
end
