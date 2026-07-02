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

ActiveRecord::Schema[8.0].define(version: 2026_07_02_232003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ZRECIPE", primary_key: "Z_PK", force: :cascade do |t|
    t.string "ZUID", null: false
    t.string "ZSYNCHASH"
    t.string "ZNAME"
    t.text "ZINGREDIENTS"
    t.text "ZDIRECTIONS"
    t.text "ZNUTRITIONALINFO"
    t.text "ZNOTES"
    t.text "ZDESCRIPTIONTEXT"
    t.integer "ZINTRASH", default: 0
    t.integer "ZRATING"
    t.string "ZSERVINGS"
    t.string "ZDIFFICULTY"
    t.string "ZCOOKTIME"
    t.string "ZPREPTIME"
    t.string "ZTOTALTIME"
    t.string "ZSOURCE"
    t.string "ZSOURCEURL"
    t.string "ZIMAGEURL"
    t.string "ZPHOTOURL"
    t.datetime "ZCREATED"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ZNAME"], name: "index_zrecipe_on_zname"
    t.index ["ZUID"], name: "index_zrecipe_on_zuid", unique: true
  end

  create_table "ZRECIPECATEGORY", primary_key: "Z_PK", force: :cascade do |t|
    t.string "ZUID", null: false
    t.string "ZNAME"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ZUID"], name: "index_zrecipecategory_on_zuid", unique: true
  end

  create_table "Z_12CATEGORIES", id: false, force: :cascade do |t|
    t.bigint "Z_12RECIPES", null: false
    t.bigint "Z_13CATEGORIES", null: false
    t.index ["Z_12RECIPES", "Z_13CATEGORIES"], name: "index_z12categories_pair", unique: true
    t.index ["Z_13CATEGORIES"], name: "index_z12categories_on_category"
  end

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
    t.bigint "user_id"
    t.index ["logged_on"], name: "index_nutrition_entries_on_logged_on"
    t.index ["user_id"], name: "index_nutrition_entries_on_user_id"
  end

  create_table "nutrition_entry_recipes", force: :cascade do |t|
    t.bigint "nutrition_entry_id", null: false
    t.integer "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nutrition_entry_id", "recipe_id"], name: "index_entry_recipes_on_entry_and_recipe", unique: true
    t.index ["nutrition_entry_id"], name: "index_nutrition_entry_recipes_on_nutrition_entry_id"
  end

  create_table "paprika_meals", force: :cascade do |t|
    t.string "uid", null: false
    t.date "scheduled_date"
    t.string "recipe_uid"
    t.integer "meal_type"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_uid"], name: "index_paprika_meals_on_recipe_uid"
    t.index ["scheduled_date"], name: "index_paprika_meals_on_scheduled_date"
    t.index ["uid"], name: "index_paprika_meals_on_uid", unique: true
  end

  create_table "user_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "calorie_goal"
    t.integer "protein_goal"
    t.integer "carbs_goal"
    t.integer "fat_goal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_settings_on_user_id", unique: true
  end

  create_table "user_staple_recipes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "recipe_id"], name: "index_staples_on_user_and_recipe", unique: true
    t.index ["user_id"], name: "index_user_staple_recipes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "nutrition_entries", "users"
  add_foreign_key "nutrition_entry_recipes", "nutrition_entries"
  add_foreign_key "user_settings", "users"
  add_foreign_key "user_staple_recipes", "users"
end
