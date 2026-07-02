# Parses a recipe's "Verified" nutrition block — nutrition entered by hand from a
# label — so the app can use those numbers directly instead of asking the LLM to
# estimate them.
class VerifiedNutrition
  NUTRIENTS = %i[calories protein carbs fat fiber saturated_fat sugar].freeze
  MARKER = "verified".freeze

  # True when the nutrition text is flagged as hand-verified (first word).
  def self.verified?(text)
    text.to_s.strip.downcase.start_with?(MARKER)
  end

  # Returns the nutrients found in the block as a hash of symbol => Float.
  # Matches one nutrient per line; saturated fat is checked before total fat.
  def self.parse(text)
    values = {}
    text.to_s.each_line do |line|
      case line
      when /saturated\s*fat\D+(\d+(?:\.\d+)?)/i then values[:saturated_fat] = num(line)
      when /\bfat\D+(\d+(?:\.\d+)?)/i           then values[:fat] = num(line)
      when /calor\D+(\d+(?:\.\d+)?)/i           then values[:calories] = num(line)
      when /protein\D+(\d+(?:\.\d+)?)/i         then values[:protein] = num(line)
      when /(?:carbohydrate|carb)\D+(\d+(?:\.\d+)?)/i then values[:carbs] = num(line)
      when /fiber\D+(\d+(?:\.\d+)?)/i           then values[:fiber] = num(line)
      when /sugar\D+(\d+(?:\.\d+)?)/i           then values[:sugar] = num(line)
      end
    end
    values
  end

  # Nutrients that a verified block is missing (so the user can be nudged).
  def self.missing(text)
    NUTRIENTS - parse(text).keys
  end

  def self.num(line)
    line[/(\d+(?:\.\d+)?)/].to_f
  end
  private_class_method :num
end
