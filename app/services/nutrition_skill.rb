# Versioned writer for the AI-generated nutrition block stored on a Paprika
# recipe's ZNUTRITIONALINFO field.
#
# The version date is stamped into the header, so bumping VERSION_DATE (e.g.
# after changing what we compute) makes every older block differ from the
# current output and get rewritten — i.e. backfilled — the next time that recipe
# is referenced.
#
# Writing can be toggled off (read-only) via ENV["NUTRITION_WRITEBACK"] so the
# app can read existing data without ever modifying the Paprika database.
class NutritionSkill
  # Bump this when the format or computed fields change to trigger backfill.
  VERSION_DATE = Date.new(2026, 7, 1)
  HEADER_PREFIX = "Meal Total (AI Generated".freeze

  class << self
    def write_enabled?
      ENV.fetch("NUTRITION_WRITEBACK", "read_write") == "read_write"
    end

    def header
      "#{HEADER_PREFIX} - #{VERSION_DATE.strftime('%-m/%-d/%y')})"
    end

    def format(batch)
      <<~INFO.strip
        #{header}
        Calories: #{batch['calories'].to_i} kcal
        Protein: #{batch['protein'].to_i} g
        Carbohydrates: #{batch['carbs'].to_i} g
        Fat: #{batch['fat'].to_i} g
      INFO
    end
  end
end
