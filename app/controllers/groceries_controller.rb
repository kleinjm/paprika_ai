class GroceriesController < ApplicationController
  def index
    # Top section: everything still to buy, across all lists, grouped by aisle,
    # with identical duplicate items collapsed into one line.
    @to_buy_by_aisle = Paprika::GroceryItem.to_buy_by_aisle
    @to_buy_count = @to_buy_by_aisle.values.sum(&:size)
    # Bottom section: what was purchased, grouped by the day we recorded it.
    @purchased_by_date = Paprika::GroceryItem
      .purchased_history
      .where.not(purchased_on: nil)
      .group_by(&:purchased_on)
  end

  # Pull the latest groceries (and everything else) from the Paprika cloud. Best
  # run right after shopping — before you "clear" the checked list in Paprika,
  # which deletes those items upstream — so the purchase gets recorded.
  def sync
    result = PaprikaSync.new.call
    redirect_to groceries_path,
                notice: "Synced from Paprika — #{result.groceries} grocery #{'item'.pluralize(result.groceries)}."
  rescue StandardError => e
    redirect_to groceries_path, alert: "Sync failed: #{e.message}"
  end
end
