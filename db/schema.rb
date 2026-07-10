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

ActiveRecord::Schema[8.0].define(version: 2026_07_10_000000) do
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

  create_table "paprika_grocery_items", force: :cascade do |t|
    t.string "uid", null: false
    t.string "name"
    t.boolean "purchased", default: false, null: false
    t.date "purchased_on"
    t.string "aisle"
    t.string "quantity"
    t.string "list_uid"
    t.string "list_name"
    t.string "recipe"
    t.string "recipe_uid"
    t.integer "order_flag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchased"], name: "index_paprika_grocery_items_on_purchased"
    t.index ["purchased_on"], name: "index_paprika_grocery_items_on_purchased_on"
    t.index ["uid"], name: "index_paprika_grocery_items_on_uid", unique: true
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

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "user_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "calorie_goal"
    t.integer "protein_goal"
    t.integer "carbs_goal"
    t.integer "fat_goal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "time_zone", default: "Pacific Time (US & Canada)", null: false
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
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "user_settings", "users"
  add_foreign_key "user_staple_recipes", "users"
end
