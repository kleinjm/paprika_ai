class CreateNutritionEntryRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :nutrition_entry_recipes do |t|
      t.references :nutrition_entry, null: false, foreign_key: true
      # References a Paprika::Recipe (ZRECIPE.Z_PK) in the read-only Paprika
      # database, so this is a plain integer rather than a foreign key.
      t.integer :recipe_id, null: false

      t.timestamps
    end

    add_index :nutrition_entry_recipes, [ :nutrition_entry_id, :recipe_id ], unique: true, name: "index_entry_recipes_on_entry_and_recipe"
  end
end
