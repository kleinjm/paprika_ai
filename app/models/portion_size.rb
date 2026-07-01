# Static list of common portion sizes offered as quick-fill pills on the
# nutrition tracking page. Not backed by a database table.
class PortionSize
  SIZES = [
    "small bowl",
    "medium bowl",
    "large bowl",
    "small plate",
    "medium plate",
    "normal plate"
  ].freeze

  def self.all
    SIZES
  end
end
