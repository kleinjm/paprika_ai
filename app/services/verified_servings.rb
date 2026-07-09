# Interprets a recipe's free-text servings/yield field (ZSERVINGS), e.g.
# "Serves 4", "Yield: 12", "3-4", or just "4". Parallels VerifiedNutrition: a
# value the user hand-flagged "Verified" is authoritative and never overwritten;
# everything else (blank, prior AI estimate, or unstandardized/garbage free text)
# is fair game for the AI to standardize. Also best-effort parses a count.
class VerifiedServings
  # First word that marks a value as hand-verified (mirrors VerifiedNutrition).
  VERIFIED_MARKER = "verified".freeze
  # Substring stamped into values this app writes (via ServingsSkill).
  MARKER = "AI Generated".freeze

  # True when the user flagged the value as hand-verified (first word).
  def self.verified?(text)
    text.to_s.strip.downcase.start_with?(VERIFIED_MARKER)
  end

  # True when the value was written by this app (used only for display).
  def self.ai_generated?(text)
    text.to_s.include?(MARKER)
  end

  # A value is safe to (over)write with an AI estimate unless it's hand-verified.
  # This matches the nutrition write-back, which overwrites anything that isn't
  # "Verified" — including blank, prior AI output, and unstandardized text.
  def self.writable?(text)
    !verified?(text)
  end

  # Best-effort serving count as an Integer, or nil. Takes the first integer in
  # the string ("Serves 4" -> 4, "Yield: 12" -> 12, "3-4" -> 3, "8 (1 cup)
  # servings" -> 8). Best-effort only: odd free text may parse imperfectly.
  def self.count(text)
    match = text.to_s[/\d+/]
    match&.to_i
  end
end
