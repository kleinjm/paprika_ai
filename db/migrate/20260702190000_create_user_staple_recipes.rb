class CreateUserStapleRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :user_staple_recipes do |t|
      t.references :user, null: false, foreign_key: true
      # References a Paprika::Recipe (ZRECIPE.Z_PK) in the read-only Paprika
      # database, so this is a plain integer rather than a foreign key.
      t.integer :recipe_id, null: false

      t.timestamps
    end

    add_index :user_staple_recipes, [ :user_id, :recipe_id ], unique: true, name: "index_staples_on_user_and_recipe"
  end
end
