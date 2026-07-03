class AddTimeZoneToUserSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :user_settings, :time_zone, :string,
               null: false, default: "Pacific Time (US & Canada)"
  end
end
