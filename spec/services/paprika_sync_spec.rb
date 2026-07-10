require "rails_helper"

RSpec.describe PaprikaSync do
  let(:client) { instance_double(PaprikaClient::Client) }
  subject(:sync) { described_class.new(client: client) }

  def full_recipe(uid, categories: [], in_trash: false)
    { "uid" => uid, "hash" => "new-#{uid}", "name" => "Test #{uid}",
      "in_trash" => in_trash, "categories" => categories }
  end

  before do
    allow(client).to receive(:categories).and_return([])
    allow(client).to receive(:recipes).and_return([])
    allow(client).to receive(:meals).and_return([])
    allow(client).to receive(:groceries).and_return([])
    allow(client).to receive(:grocery_lists).and_return([])
  end

  def grocery(uid, purchased:, list_uid: "L1", aisle: "Produce")
    { "uid" => uid, "name" => "Item #{uid}", "purchased" => purchased,
      "aisle" => aisle, "quantity" => "1", "list_uid" => list_uid,
      "recipe" => nil, "recipe_uid" => nil, "order_flag" => 1 }
  end

  # Seed pre-existing mirror rows the way a real sync would — inside the syncing
  # window the read-only guard requires. Plain create! outside it raises.
  def seed_mirror(&block)
    Paprika::ApplicationRecord.syncing(&block)
  end

  it "upserts categories, changed recipes (with category links), and meals" do
    allow(client).to receive(:categories).and_return(
      [ { "uid" => "cat-1", "name" => "Dinner" }, { "uid" => "cat-2", "name" => "Vegan" } ]
    )
    allow(client).to receive(:recipes).and_return([ { "uid" => "r-1", "hash" => "new-r-1" } ])
    allow(client).to receive(:recipe).with("r-1")
      .and_return(full_recipe("r-1", categories: [ "cat-1", "unknown-cat" ]))
    allow(client).to receive(:meals).and_return(
      [ { "uid" => "m-1", "date" => "2026-07-05", "recipe_uid" => "r-1", "type" => 0, "name" => "Dinner" } ]
    )

    result = sync.call

    recipe = Paprika::Recipe.find_by(ZUID: "r-1")
    expect(recipe.name).to eq("Test r-1")
    expect(recipe.recipe_categories.pluck(:ZUID)).to eq([ "cat-1" ]) # unknown-cat filtered out
    expect(Paprika::Meal.find_by(uid: "m-1").recipe_uid).to eq("r-1")
    expect(result.to_h).to eq(categories: 2, recipes_changed: 1, meals: 1, groceries: 0)
  end

  it "skips recipes whose sync hash is unchanged" do
    seed_mirror { Paprika::Recipe.create!(ZUID: "r-1", ZSYNCHASH: "new-r-1", ZNAME: "old") }
    allow(client).to receive(:recipes).and_return([ { "uid" => "r-1", "hash" => "new-r-1" } ])
    expect(client).not_to receive(:recipe)

    expect(sync.call.recipes_changed).to eq(0)
  end

  it "drops a newly-trashed recipe that nothing references" do
    recipe = seed_mirror { Paprika::Recipe.create!(ZUID: "r-x", ZSYNCHASH: "old", ZNAME: "gone") }
    allow(client).to receive(:recipes).and_return([ { "uid" => "r-x", "hash" => "new-r-x" } ])
    allow(client).to receive(:recipe).with("r-x").and_return(full_recipe("r-x", in_trash: true))

    expect { sync.call }.to change { Paprika::Recipe.exists?(recipe.Z_PK) }.from(true).to(false)
  end

  it "keeps a trashed recipe that a staple still references" do
    recipe = seed_mirror { Paprika::Recipe.create!(ZUID: "r-y", ZSYNCHASH: "old", ZNAME: "keep") }
    user = User.create!(email: "s@example.com", password: "password")
    user.user_staple_recipes.create!(recipe_id: recipe.Z_PK)
    allow(client).to receive(:recipes).and_return([ { "uid" => "r-y", "hash" => "new-r-y" } ])
    allow(client).to receive(:recipe).with("r-y").and_return(full_recipe("r-y", in_trash: true))

    expect { sync.call }.not_to(change { Paprika::Recipe.exists?(recipe.Z_PK) })
  end

  it "ignores a trashed recipe that isn't in the mirror" do
    allow(client).to receive(:recipes).and_return([ { "uid" => "r-z", "hash" => "new-r-z" } ])
    allow(client).to receive(:recipe).with("r-z").and_return(full_recipe("r-z", in_trash: true))

    expect { sync.call }.not_to change(Paprika::Recipe, :count)
    expect(sync.call.recipes_changed).to eq(0)
  end

  describe "groceries" do
    subject(:sync) { described_class.new(client: client, today: Date.new(2026, 7, 10)) }

    it "upserts items across all lists with resolved list names, unstamped on first sight" do
      allow(client).to receive(:grocery_lists).and_return(
        [ { "uid" => "L1", "name" => "Home" }, { "uid" => "L2", "name" => "Kate" } ]
      )
      allow(client).to receive(:groceries).and_return(
        [ grocery("g-1", purchased: false, list_uid: "L1"),
          grocery("g-2", purchased: true, list_uid: "L2") ]
      )

      expect(sync.call.groceries).to eq(2)

      to_buy = Paprika::GroceryItem.find_by(uid: "g-1")
      expect(to_buy.list_name).to eq("Home")
      expect(to_buy.purchased_on).to be_nil
      # Already purchased the first time we see it -> no invented date.
      expect(Paprika::GroceryItem.find_by(uid: "g-2").purchased_on).to be_nil
    end

    it "stamps today only when it witnesses a to-buy item flip to purchased" do
      allow(client).to receive(:groceries).and_return([ grocery("g-1", purchased: false) ])
      sync.call
      expect(Paprika::GroceryItem.find_by(uid: "g-1").purchased_on).to be_nil

      allow(client).to receive(:groceries).and_return([ grocery("g-1", purchased: true) ])
      described_class.new(client: client, today: Date.new(2026, 7, 11)).call

      item = Paprika::GroceryItem.find_by(uid: "g-1")
      expect(item.purchased).to be(true)
      expect(item.purchased_on).to eq(Date.new(2026, 7, 11))
    end

    it "keeps purchased history but drops unpurchased items that vanish from the cloud" do
      allow(client).to receive(:groceries).and_return(
        [ grocery("keep", purchased: false), grocery("gone", purchased: false) ]
      )
      sync.call
      # Witness both being purchased so they carry a date, then clear upstream.
      allow(client).to receive(:groceries).and_return(
        [ grocery("keep", purchased: true), grocery("gone", purchased: true) ]
      )
      described_class.new(client: client, today: Date.new(2026, 7, 11)).call

      # Next sync: "gone" removed from the cloud entirely, "keep" still there.
      allow(client).to receive(:groceries).and_return([ grocery("keep", purchased: true) ])
      described_class.new(client: client, today: Date.new(2026, 7, 12)).call

      expect(Paprika::GroceryItem.pluck(:uid)).to contain_exactly("keep", "gone")
    end

    it "removes an unpurchased item deleted before it was ever bought" do
      allow(client).to receive(:groceries).and_return([ grocery("g-1", purchased: false) ])
      sync.call
      allow(client).to receive(:groceries).and_return([ grocery("g-2", purchased: false) ])
      sync.call

      expect(Paprika::GroceryItem.exists?(uid: "g-1")).to be(false)
    end
  end
end
