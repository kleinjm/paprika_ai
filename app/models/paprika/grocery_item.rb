module Paprika
  # Local mirror of a Paprika grocery item (table "paprika_grocery_items"),
  # populated from the Paprika cloud via `paprika:pull`.
  #
  # The cloud exposes only a `purchased` boolean — no purchase date — so we own
  # `purchased_on`, stamping it the first time we observe an item as purchased.
  # Paprika deletes items from the cloud when you "clear" a checked list, so the
  # sync keeps purchased items as history even after they disappear upstream (see
  # PaprikaSync#sync_groceries); only unpurchased items that vanish are dropped.
  class GroceryItem < ApplicationRecord
    self.table_name = "paprika_grocery_items"

    # Still-to-buy items, in shopping order (aisle, then Paprika's own ordering).
    scope :to_buy, -> { where(purchased: false).order(:aisle, :order_flag, :name) }
    # Purchased items, most recent first — the "what did I buy" history.
    scope :purchased_history, -> { where(purchased: true).order(purchased_on: :desc, aisle: :asc, name: :asc) }

    # Aisle label for grouping, with a sensible fallback for blank aisles.
    def aisle_label
      aisle.presence || "Other"
    end
  end
end
