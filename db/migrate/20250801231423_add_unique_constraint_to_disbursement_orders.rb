class AddUniqueConstraintToDisbursementOrders < ActiveRecord::Migration[7.1]
  def change
    add_index :disbursement_orders,
              :order_id,
              unique: true,
              name: 'index_disbursement_orders_on_order_id_unique'
  end
end
