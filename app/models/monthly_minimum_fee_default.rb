# typed: strict

class MonthlyMinimumFeeDefault < ApplicationRecord
  extend T::Sig

  belongs_to :merchant, class_name: 'Merchant', optional: false

  validates :minimum_monthly_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :actual_commission_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :defaulted_amount, presence: true, numericality: { greater_than: 0 }
  validates :period_date, presence: true
  validates :period_date, uniqueness: { scope: :merchant_id }
end
