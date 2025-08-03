class CreateCommissionsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :commissions do |t|
      t.uuid :disbursement_id, null: false
      t.string :order_id, null: false
      t.decimal :commission_amount, precision: 10, scale: 2, null: false
      t.decimal :commission_rate, null: false
      t.date :commission_date, null: false

      t.timestamps
    end

    add_index :commissions, :order_id, unique: true
    add_index :commissions,
              %i[disbursement_id order_id],
              unique: true,
              name: 'index_commissions_on_disbursement_and_order_unique'
  end
end
