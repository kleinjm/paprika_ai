# Versioned writer for the AI-estimated serving count stored on a Paprika
# recipe's ZSERVINGS field. Mirrors NutritionSkill: the version date is stamped
# into the value, so bumping VERSION_DATE makes older AI-written values differ
# from the current output and get rewritten (backfilled) the next time the
# recipe is referenced.
#
# User-entered servings (any non-blank value we didn't write) are treated as
# authoritative and never overwritten — see VerifiedServings. Writing honors the
# same ENV["NUTRITION_WRITEBACK"] read-only toggle as NutritionSkill.
class ServingsSkill
  # Bump this when the format changes to trigger backfill of AI-written values.
  VERSION_DATE = Date.new(2026, 7, 8)

  class << self
    def write_enabled?
      NutritionSkill.write_enabled?
    end

    # e.g. "4 servings (AI Generated - 7/8/26)"
    def format(count)
      n = count.to_i
      return nil unless n.positive?

      "#{n} #{'serving'.pluralize(n)} (#{VerifiedServings::MARKER} - #{VERSION_DATE.strftime('%-m/%-d/%y')})"
    end
  end
end
