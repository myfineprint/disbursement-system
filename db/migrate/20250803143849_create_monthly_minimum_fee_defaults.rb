# typed: true
class CreateMonthlyMinimumFeeDefaults < ActiveRecord::Migration[7.1]
  def change
    create_table :monthly_minimum_fee_defaults, id: :uuid do |t|
      t.references :merchant, null: false, type: :uuid
      t.decimal :minimum_monthly_fee, precision: 10, scale: 2, null: false
      t.decimal :actual_commission_paid, precision: 10, scale: 2, null: false
      t.decimal :defaulted_amount, precision: 10, scale: 2, null: false
      t.date :period_date, null: false

      t.timestamps
    end

    add_index :monthly_minimum_fee_defaults,
              %i[merchant_id period_date],
              unique: true,
              name: 'index_monthly_minimum_fee_defaults_on_merchant_and_period'
  end
end
