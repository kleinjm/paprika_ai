module Paprika
  # Paprika data now lives in the primary application database as a local
  # mirror of the Paprika cloud (populated via the paprika_client gem). These
  # models therefore use the default connection — no separate database.
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
