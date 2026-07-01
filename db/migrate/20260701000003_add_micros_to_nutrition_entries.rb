class AddMicrosToNutritionEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :nutrition_entries, :fiber, :decimal, precision: 6, scale: 1
    add_column :nutrition_entries, :saturated_fat, :decimal, precision: 6, scale: 1
    add_column :nutrition_entries, :sugar, :decimal, precision: 6, scale: 1
  end
end
