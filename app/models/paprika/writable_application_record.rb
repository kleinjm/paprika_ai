module Paprika
  # Separate, writable connection to the same Paprika SQLite database.
  # Used only to persist AI-computed batch macros into ZRECIPE.ZNUTRITIONALINFO.
  class WritableApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    establish_connection :writable_paprika
  end
end
