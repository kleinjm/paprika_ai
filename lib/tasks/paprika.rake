# frozen_string_literal: true

namespace :paprika do
  desc "Pull recipes, categories, and meals from the Paprika cloud into the local mirror"
  task pull: :environment do
    result = PaprikaSync.new.call
    puts "categories: #{result.categories}"
    puts "recipes: #{result.recipes_changed} added/updated"
    puts "meals: #{result.meals}"
    puts "groceries: #{result.groceries}"
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

# Core Data stores timestamps as seconds since 2001-01-01 UTC.
def cocoa_to_time(value)
  return if value.nil?

  Time.at(value.to_f + 978_307_200)
end
