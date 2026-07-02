class CreateUserSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :user_settings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :calorie_goal
      t.integer :protein_goal
      t.integer :carbs_goal
      t.integer :fat_goal

      t.timestamps
    end
  end
end
