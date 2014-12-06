class CreateSpreePlanGateways < ActiveRecord::Migration
  def change
    create_table :spree_plan_gateways do |t|
      t.integer :plan_id
      t.integer :payment_method_id
      t.string  :api_plan_id
    end

    add_index :spree_subscriptions, :plan_id,:payment_method_id
    add_index :spree_subscriptions, :plan_id
  end
end
