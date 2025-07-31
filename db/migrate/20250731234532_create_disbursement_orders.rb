class CreateDisbursementOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :disbursement_orders do |t|
      t.uuid :disbursement_id
      t.uuid :order_id

      t.timestamps
    end
    add_index :disbursement_orders, :disbursement_id
    add_index :disbursement_orders, :order_id
  end
end
