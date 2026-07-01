# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_07_01_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "nutrition_entries", force: :cascade do |t|
    t.date "logged_on", null: false
    t.text "raw_input"
    t.string "item", null: false
    t.integer "calories"
    t.decimal "protein", precision: 6, scale: 1
    t.decimal "carbs", precision: 6, scale: 1
    t.decimal "fat", precision: 6, scale: 1
    t.string "recipe_match"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "fiber", precision: 6, scale: 1
    t.decimal "saturated_fat", precision: 6, scale: 1
    t.decimal "sugar", precision: 6, scale: 1
    t.index ["logged_on"], name: "index_nutrition_entries_on_logged_on"
  end

  create_table "nutrition_entry_recipes", force: :cascade do |t|
    t.bigint "nutrition_entry_id", null: false
    t.integer "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutrition_entry_id", "recipe_id"], name: "index_entry_recipes_on_entry_and_recipe", unique: true
    t.index ["nutrition_entry_id"], name: "index_nutrition_entry_recipes_on_nutrition_entry_id"
  end

  add_foreign_key "nutrition_entry_recipes", "nutrition_entries"
end
