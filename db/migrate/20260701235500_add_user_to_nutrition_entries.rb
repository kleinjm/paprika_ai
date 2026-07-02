class AddUserToNutritionEntries < ActiveRecord::Migration[8.0]
  def change
    # Nullable so the migration is safe on existing rows; new records always set
    # a user (belongs_to :user), and orphaned legacy rows are simply never shown.
    add_reference :nutrition_entries, :user, foreign_key: true, null: true
  end
end
