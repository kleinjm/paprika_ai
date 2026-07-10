require "rails_helper"

RSpec.describe "Groceries", type: :request do
  let(:user) { User.create!(email: "groceries@example.com", password: "password") }

  before { sign_in user }

  # Grocery rows are part of the read-only Paprika mirror, so seed them the way a
  # sync would — inside the syncing window the guard requires.
  def seed(attrs)
    Paprika::ApplicationRecord.syncing { Paprika::GroceryItem.create!(attrs) }
  end

  it "requires authentication" do
    sign_out user
    get groceries_path
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "GET /groceries" do
    it "lists to-buy items by aisle (across lists) and purchases grouped by date" do
      seed(uid: "b1", name: "Bananas", purchased: false, aisle: "Produce", list_name: "Home", quantity: "6")
      seed(uid: "b2", name: "Milk", purchased: false, aisle: "Dairy", list_name: "Kate")
      seed(uid: "p1", name: "Bread", purchased: true, purchased_on: Date.new(2026, 7, 8), aisle: "Bakery")
      seed(uid: "p2", name: "Eggs", purchased: true, purchased_on: Date.new(2026, 7, 8), aisle: "Dairy")

      get groceries_path

      expect(response).to have_http_status(:ok)
      # To Buy section
      expect(response.body).to include("To Buy")
      expect(response.body).to include("Bananas")
      expect(response.body).to include("Produce")
      expect(response.body).to include("Kate")   # list badge — all lists included
      # Recently purchased, grouped by day
      expect(response.body).to include("Recently Purchased")
      expect(response.body).to include("Wednesday, July 8, 2026")
      expect(response.body).to include("Bread")
      expect(response.body).to include("Eggs")
    end

    it "collapses identical duplicate to-buy items into one line with a count" do
      4.times { |n| seed(uid: "e#{n}", name: "eggs", purchased: false, aisle: "ALWAYS GET", list_name: "Home") }

      get groceries_path

      # One "eggs" line with a ×4 badge, not four separate rows.
      expect(response.body).to include("×4")
      expect(response.body.scan(/>eggs</).size).to eq(1)
    end

    it "shows empty states when there's nothing to buy or purchased" do
      get groceries_path
      expect(response.body).to include("all caught up")
      expect(response.body).to include("No purchases recorded yet")
    end
  end

  describe "POST /groceries/sync" do
    it "syncs and redirects with a summary notice" do
      result = PaprikaSync::Result.new(categories: 1, recipes_changed: 0, meals: 2, groceries: 42)
      allow(PaprikaSync).to receive(:new).and_return(instance_double(PaprikaSync, call: result))

      post groceries_sync_path

      expect(response).to redirect_to(groceries_path)
      follow_redirect!
      expect(response.body).to include("42 grocery items")
    end

    it "redirects with an alert when the sync fails" do
      allow(PaprikaSync).to receive(:new).and_return(instance_double(PaprikaSync).tap do |s|
        allow(s).to receive(:call).and_raise(StandardError, "cloud down")
      end)

      post groceries_sync_path

      expect(response).to redirect_to(groceries_path)
      follow_redirect!
      expect(response.body).to include("Sync failed: cloud down")
    end
  end
end
