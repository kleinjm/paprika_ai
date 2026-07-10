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

    # A collapsed to-buy line. Paprika can hold several identical items (e.g. a
    # recurring "eggs" staple added many times); we merge them into one row with
    # a count so the list stays readable.
    Line = Struct.new(:name, :quantity, :list_name, :count, keyword_init: true)

    # To-buy items grouped by aisle, with identical items (same name + quantity +
    # list) collapsed into a single Line carrying how many there were.
    def self.to_buy_by_aisle
      to_buy.group_by(&:aisle_label).transform_values do |items|
        items
          .group_by { |item| [ item.name, item.quantity.presence, item.list_name ] }
          .map do |(name, quantity, list_name), group|
            Line.new(name: name, quantity: quantity, list_name: list_name, count: group.size)
          end
      end
    end

    # Aisle label for grouping, with a sensible fallback for blank aisles.
    def aisle_label
      aisle.presence || "Other"
    end
  end
end
