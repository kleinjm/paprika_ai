class CreateNutritionEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :nutrition_entries do |t|
      t.date :logged_on, null: false
      t.text :raw_input
      t.string :item, null: false
      t.integer :calories
      t.decimal :protein, precision: 6, scale: 1
      t.decimal :carbs, precision: 6, scale: 1
      t.decimal :fat, precision: 6, scale: 1
      t.string :recipe_match

      t.timestamps
    end

    add_index :nutrition_entries, :logged_on
  end
end
