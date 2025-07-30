class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders, id: :string do |t|
      t.string :merchant_reference
      t.decimal :amount

      t.timestamps
    end
  end
end
