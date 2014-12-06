class CreateSpreePlan < ActiveRecord::Migration
  def self.up
    create_table :spree_plans do |t|
      t.integer :variant_id
      t.decimal :amount
      t.string :interval
      t.integer :interval_count, :default => 1
      t.string :name
      t.string :currency
      t.integer :trial_period_days, :default => 0
      t.boolean :active, :default => false
      t.datetime :deleted_at
    end

    add_index :spree_plans, [:deleted_at, :active]
    add_index :spree_plans, :deleted_at
  end
  def self.down
    drop_table :spree_plans 
  end
end
