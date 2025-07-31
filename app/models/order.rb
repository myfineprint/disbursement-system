# typed: strict

class Order < ApplicationRecord
  extend T::Sig

  belongs_to :merchant,
             foreign_key: 'merchant_reference',
             primary_key: 'reference',
             inverse_of: :orders
  has_many :disbursement_orders, dependent: :destroy
  has_many :disbursements, through: :disbursement_orders

  validates :merchant_reference, presence: true
  validates :amount,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0
            }
  validates :created_at, presence: true

  scope :eligible_for_disbursement,
        lambda { |date = Date.current|
          joins(:merchant).where(merchants: { live_on: ..date }).where(
            'DATE(orders.created_at) >= merchants.live_on'
          )
        }
end
