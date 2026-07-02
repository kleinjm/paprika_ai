# frozen_string_literal: true

# Local mirror of the Paprika Recipe Manager data, populated from the Paprika
# cloud sync API (via the paprika_client gem). The recipe/category tables keep
# Paprika's Core Data names and Z_PK primary key so existing references
# (recipe_id columns, params, find_by(Z_PK:)) keep working unchanged. Meals use
# a clean schema keyed by recipe uid.
class CreatePaprikaMirror < ActiveRecord::Migration[8.0]
  def change
    create_table "ZRECIPE", primary_key: "Z_PK", id: :bigint do |t|
      t.string   "ZUID",             null: false
      t.string   "ZSYNCHASH"
      t.string   "ZNAME"
      t.text     "ZINGREDIENTS"
      t.text     "ZDIRECTIONS"
      t.text     "ZNUTRITIONALINFO"
      t.text     "ZNOTES"
      t.text     "ZDESCRIPTIONTEXT"
      t.integer  "ZINTRASH",         default: 0
      t.integer  "ZRATING"
      t.string   "ZSERVINGS"
      t.string   "ZDIFFICULTY"
      t.string   "ZCOOKTIME"
      t.string   "ZPREPTIME"
      t.string   "ZTOTALTIME"
      t.string   "ZSOURCE"
      t.string   "ZSOURCEURL"
      t.string   "ZIMAGEURL"
      t.string   "ZPHOTOURL"
      t.datetime "ZCREATED"
      t.timestamps
    end
    add_index "ZRECIPE", "ZUID", unique: true, name: "index_zrecipe_on_zuid"
    add_index "ZRECIPE", "ZNAME", name: "index_zrecipe_on_zname"

    create_table "ZRECIPECATEGORY", primary_key: "Z_PK", id: :bigint do |t|
      t.string "ZUID", null: false
      t.string "ZNAME"
      t.timestamps
    end
    add_index "ZRECIPECATEGORY", "ZUID", unique: true, name: "index_zrecipecategory_on_zuid"

    # Join table: recipe (Z_12RECIPES) <-> recipe category (Z_13CATEGORIES).
    create_table "Z_12CATEGORIES", id: false do |t|
      t.bigint "Z_12RECIPES",    null: false
      t.bigint "Z_13CATEGORIES", null: false
    end
    add_index "Z_12CATEGORIES", %w[Z_12RECIPES Z_13CATEGORIES], unique: true, name: "index_z12categories_pair"
    add_index "Z_12CATEGORIES", "Z_13CATEGORIES", name: "index_z12categories_on_category"

    create_table :paprika_meals do |t|
      t.string  :uid, null: false
      t.date    :scheduled_date
      t.string  :recipe_uid
      t.integer :meal_type
      t.string  :name
      t.timestamps
    end
    add_index :paprika_meals, :uid, unique: true
    add_index :paprika_meals, :scheduled_date
    add_index :paprika_meals, :recipe_uid
  end
end
