class CreatePaprikaGroceryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :paprika_grocery_items do |t|
      t.string :uid, null: false
      t.string :name
      t.boolean :purchased, null: false, default: false
      # Owned by us: the API has no purchase date, so we stamp the date we first
      # observe an item as purchased. Null while it's still "to buy".
      t.date :purchased_on
      t.string :aisle
      t.string :quantity
      t.string :list_uid
      t.string :list_name
      t.string :recipe
      t.string :recipe_uid
      t.integer :order_flag

      t.timestamps
    end

    add_index :paprika_grocery_items, :uid, unique: true
    add_index :paprika_grocery_items, :purchased
    add_index :paprika_grocery_items, :purchased_on
  end
end
