# Static list of common portion sizes offered as quick-fill pills on the
# nutrition tracking page. Not backed by a database table.
#
# The serving-count pills ("1 serving", etc.) are explicit on purpose: paired
# with a matched recipe they let the controller compute the portion
# deterministically (batch nutrition x qty / yield) instead of asking the LLM to
# guess what "a medium bowl" means — see NutritionController#direct_serving_entries.
# The generic units below (handful, cup, ...) are for eating-out foods that have
# no recipe to anchor to and still flow through the LLM.
class PortionSize
  SIZES = [
    "0.5 serving",
    "1 serving",
    "1.5 servings",
    "2 servings",
    "handful",
    "cup",
    "slice",
    "glass"
  ].freeze

  def self.all
    SIZES
  end
end
