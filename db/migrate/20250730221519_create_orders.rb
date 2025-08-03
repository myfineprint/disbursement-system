# typed: true
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders, id: :string do |t|
      t.string :merchant_reference
      t.decimal :amount

      t.timestamps
    end

    # Add default value for ID column to generate 12-character hex strings
    execute 'ALTER TABLE orders ALTER COLUMN id SET DEFAULT substr(md5(random()::text), 1, 12)'
  end
end
