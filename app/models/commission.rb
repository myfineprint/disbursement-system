# typed: strict

class Commission < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :disbursement, class_name: 'Disbursement', optional: false
  belongs_to :order, class_name: 'Order', optional: false
  delegate :merchant, to: :order

  # Validations
  validates :commission_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_rate,
            presence: true,
            inclusion: {
              in: Enums::CommissionRates.values.map(&:serialize)
            },
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 1
            }
  validates :order_id, uniqueness: true

  # Scopes
  scope :for_disbursement, ->(disbursement_id) { where(disbursement_id: disbursement_id) }
  scope :for_order, ->(order_id) { where(order_id: order_id) }
end
