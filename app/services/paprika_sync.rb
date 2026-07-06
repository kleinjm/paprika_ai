# frozen_string_literal: true

# Pulls categories, recipes, and scheduled meals from the Paprika cloud into the
# local mirror. Shared by the scheduled `paprika:pull` task and the in-app
# "Sync meals" control. Recipes are incremental (by sync hash); meals are bulk
# upserted so a manual sync stays fast enough for a web request.
class PaprikaSync
  Result = Struct.new(:categories, :recipes_changed, :meals, keyword_init: true)

  def initialize(client: PaprikaCloud.client)
    @client = client
  end

  def call
    category_pks = sync_categories
    changed = sync_recipes(category_pks)
    meals = sync_meals
    Result.new(categories: category_pks.size, recipes_changed: changed, meals: meals)
  end

  private

  attr_reader :client

  # Upsert categories by uid; return a { uid => Z_PK } map for linking recipes.
  def sync_categories
    client.categories.each_with_object({}) do |cat, pk_by_uid|
      record = Paprika::RecipeCategory.find_or_initialize_by(ZUID: cat["uid"])
      record.name = cat["name"]
      record.save!
      pk_by_uid[cat["uid"]] = record.Z_PK
    end
  end

  # Fetch and upsert only recipes whose sync hash changed; drop trashed ones.
  def sync_recipes(category_pks)
    known_hashes = Paprika::Recipe.pluck(:ZUID, :ZSYNCHASH).to_h
    changed = 0

    client.recipes.each do |summary|
      uid = summary["uid"]
      next if known_hashes[uid] == summary["hash"]

      full = client.recipe(uid)
      if trashed?(full)
        remove_from_mirror(uid)
        next
      end

      record = Paprika::Recipe.find_or_initialize_by(ZUID: uid)
      record.assign_attributes(recipe_attributes(full))
      record.save!
      rebuild_categories(record, Array(full["categories"]), category_pks)
      changed += 1
    end

    changed
  end

  # Bulk upsert every scheduled meal in a single statement (keyed by uid).
  def sync_meals
    now = Time.current
    rows = client.meals.map do |meal|
      {
        uid: meal["uid"],
        scheduled_date: meal["date"],
        recipe_uid: meal["recipe_uid"],
        meal_type: meal["type"],
        name: meal["name"],
        created_at: now,
        updated_at: now
      }
    end
    Paprika::Meal.upsert_all(rows, unique_by: :uid) if rows.any?
    rows.size
  end

  def recipe_attributes(full)
    {
      ZSYNCHASH: full["hash"],
      ZNAME: full["name"],
      ZINGREDIENTS: full["ingredients"],
      ZDIRECTIONS: full["directions"],
      ZNUTRITIONALINFO: full["nutritional_info"],
      ZNOTES: full["notes"],
      ZDESCRIPTIONTEXT: full["description"],
      ZINTRASH: 0,
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
    }
  end

  def trashed?(full)
    !!full["in_trash"]
  end

  # Remove a recipe (and its category joins) unless a staple or nutrition entry
  # still points at it — those references use Z_PK, so deleting a referenced
  # recipe would orphan user data.
  def remove_from_mirror(uid)
    recipe = Paprika::Recipe.find_by(ZUID: uid)
    return unless recipe
    return if UserStapleRecipe.exists?(recipe_id: recipe.Z_PK) ||
              NutritionEntryRecipe.exists?(recipe_id: recipe.Z_PK)

    Paprika::Category.where(Z_12RECIPES: recipe.Z_PK).delete_all
    recipe.destroy!
  end

  def rebuild_categories(recipe, category_uids, pk_by_uid)
    Paprika::Category.where(Z_12RECIPES: recipe.Z_PK).delete_all
    pairs = category_uids.filter_map do |cat_uid|
      pk = pk_by_uid[cat_uid]
      { "Z_12RECIPES" => recipe.Z_PK, "Z_13CATEGORIES" => pk } if pk
    end
    Paprika::Category.insert_all(pairs) if pairs.any?
  end
end
