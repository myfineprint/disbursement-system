class CreateDisbursements < ActiveRecord::Migration[7.1]
  def change
    create_table :disbursements do |t|
      t.uuid :merchant_id, null: false
      t.string :frequency, null: false
      t.date :disbursement_date, null: false
      t.decimal :total_gross_amount, precision: 10, scale: 2, null: false
      t.decimal :total_commission, precision: 10, scale: 2, null: false
      t.decimal :total_net_amount, precision: 10, scale: 2, null: false
      t.string :reference, null: false

      t.timestamps
    end
    add_index :disbursements, :merchant_id
    add_index :disbursements, :reference
  end
end
