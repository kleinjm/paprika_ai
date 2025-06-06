module Paprika
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    establish_connection :readonly_paprika
  end
end
