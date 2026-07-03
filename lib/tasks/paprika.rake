# frozen_string_literal: true

namespace :paprika do
  desc "Pull recipes, categories, and meals from the Paprika cloud into the local mirror"
  task pull: :environment do
    client = PaprikaCloud.client

    # --- Categories: upsert by uid, remember uid -> Z_PK -------------------
    category_pk_by_uid = {}
    client.categories.each do |cat|
      record = Paprika::RecipeCategory.find_or_initialize_by(ZUID: cat["uid"])
      record.name = cat["name"]
      record.save!
      category_pk_by_uid[cat["uid"]] = record.Z_PK
    end
    puts "categories: #{category_pk_by_uid.size}"

    # --- Recipes: incremental by sync hash ---------------------------------
    known_hashes = Paprika::Recipe.pluck(:ZUID, :ZSYNCHASH).to_h
    changed = 0
    client.recipes.each do |summary|
      uid = summary["uid"]
      next if known_hashes[uid] == summary["hash"] # unchanged since last pull

      full = client.recipe(uid)

      # The app only ever uses live recipes, so keep trashed ones out of the
      # mirror (and drop any that were just trashed, unless referenced by user
      # data, to avoid orphaning staples/nutrition entries).
      if bool_to_int(full["in_trash"]) == 1
        remove_from_mirror(uid)
        next
      end

      record = Paprika::Recipe.find_or_initialize_by(ZUID: uid)
      record.assign_attributes(
        ZSYNCHASH: full["hash"],
        ZNAME: full["name"],
        ZINGREDIENTS: full["ingredients"],
        ZDIRECTIONS: full["directions"],
        ZNUTRITIONALINFO: full["nutritional_info"],
        ZNOTES: full["notes"],
        ZDESCRIPTIONTEXT: full["description"],
        ZINTRASH: bool_to_int(full["in_trash"]),
        ZRATING: full["rating"],
        ZSERVINGS: full["servings"],
        ZDIFFICULTY: full["difficulty"],
        ZCOOKTIME: full["cook_time"],
        ZPREPTIME: full["prep_time"],
        ZTOTALTIME: full["total_time"],
        ZSOURCE: full["source"],
        ZSOURCEURL: full["source_url"],
        ZIMAGEURL: full["image_url"],
        ZPHOTOURL: full["photo_url"],
        ZCREATED: full["created"]
      )
      record.save!
      sync_categories(record, Array(full["categories"]), category_pk_by_uid)
      changed += 1
    end
    puts "recipes: #{changed} added/updated, #{known_hashes.size} previously known"

    # --- Meals -------------------------------------------------------------
    client.meals.each do |meal|
      record = Paprika::Meal.find_or_initialize_by(uid: meal["uid"])
      record.assign_attributes(
        scheduled_date: meal["date"],
        recipe_uid: meal["recipe_uid"],
        meal_type: meal["type"],
        name: meal["name"]
      )
      record.save!
    end
    puts "meals: #{Paprika::Meal.count}"
  end

  desc "One-time dev seed: copy the local Paprika SQLite DB into the mirror, preserving Z_PK"
  task seed_from_sqlite: :environment do
    require "sqlite3"

    path = ENV.fetch("PAPRIKA_DATABASE_PATH") do
      "/Users/jklein/Library/Group Containers/72KVKW69K8.com.hindsightlabs.paprika.mac.v3/" \
      "Data/Database/Paprika.sqlite"
    end
    db = SQLite3::Database.new(path, readonly: true)
    db.results_as_hash = true

    db.execute("SELECT Z_PK, ZUID, ZSYNCHASH, ZNAME, ZINGREDIENTS, ZDIRECTIONS, ZNUTRITIONALINFO, " \
               "ZNOTES, ZDESCRIPTIONTEXT, ZINTRASH, ZRATING, ZSERVINGS, ZDIFFICULTY, ZCOOKTIME, " \
               "ZPREPTIME, ZTOTALTIME, ZSOURCE, ZSOURCEURL, ZIMAGEURL, ZCREATED FROM ZRECIPE").each do |row|
      rec = Paprika::Recipe.find_or_initialize_by(Z_PK: row["Z_PK"])
      rec.assign_attributes(row.slice(*%w[ZUID ZSYNCHASH ZNAME ZINGREDIENTS ZDIRECTIONS
                                          ZNUTRITIONALINFO ZNOTES ZDESCRIPTIONTEXT ZINTRASH ZRATING
                                          ZSERVINGS ZDIFFICULTY ZCOOKTIME ZPREPTIME ZTOTALTIME
                                          ZSOURCE ZSOURCEURL ZIMAGEURL]))
      rec.ZCREATED = cocoa_to_time(row["ZCREATED"])
      rec.save!
    end

    db.execute("SELECT Z_PK, ZUID, ZNAME FROM ZRECIPECATEGORY").each do |row|
      cat = Paprika::RecipeCategory.find_or_initialize_by(Z_PK: row["Z_PK"])
      cat.assign_attributes(ZUID: row["ZUID"], ZNAME: row["ZNAME"])
      cat.save!
    end

    Paprika::Category.delete_all
    rows = db.execute("SELECT Z_12RECIPES, Z_13CATEGORIES FROM Z_12CATEGORIES")
    Paprika::Category.insert_all(rows.map { |r| { "Z_12RECIPES" => r["Z_12RECIPES"], "Z_13CATEGORIES" => r["Z_13CATEGORIES"] } }) if rows.any?

    # We inserted explicit Z_PKs; advance the sequences so later `pull` inserts
    # don't collide with seeded ids.
    conn = ActiveRecord::Base.connection
    conn.reset_pk_sequence!("ZRECIPE", "Z_PK")
    conn.reset_pk_sequence!("ZRECIPECATEGORY", "Z_PK")

    puts "seeded: #{Paprika::Recipe.count} recipes, #{Paprika::RecipeCategory.count} categories"
  end
end

def bool_to_int(value)
  value ? 1 : 0
end

# Remove a recipe (and its category joins) from the mirror by uid, unless a
# staple or nutrition entry still points at it — those references use Z_PK, so
# deleting a referenced recipe would orphan user data.
def remove_from_mirror(uid)
  recipe = Paprika::Recipe.find_by(ZUID: uid)
  return unless recipe
  return if UserStapleRecipe.exists?(recipe_id: recipe.Z_PK) ||
            NutritionEntryRecipe.exists?(recipe_id: recipe.Z_PK)

  Paprika::Category.where(Z_12RECIPES: recipe.Z_PK).delete_all
  recipe.destroy!
end

# Rebuild a recipe's category join rows from the cloud category-uid list.
def sync_categories(recipe, category_uids, pk_by_uid)
  Paprika::Category.where(Z_12RECIPES: recipe.Z_PK).delete_all
  pairs = category_uids.filter_map do |cat_uid|
    pk = pk_by_uid[cat_uid]
    { "Z_12RECIPES" => recipe.Z_PK, "Z_13CATEGORIES" => pk } if pk
  end
  Paprika::Category.insert_all(pairs) if pairs.any?
end

# Core Data stores timestamps as seconds since 2001-01-01 UTC.
def cocoa_to_time(value)
  return if value.nil?

  Time.at(value.to_f + 978_307_200)
end
