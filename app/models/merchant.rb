# typed: strict

class Merchant < ApplicationRecord
  has_many :orders,
           class_name: 'Order',
           foreign_key: 'merchant_reference',
           primary_key: 'reference',
           dependent: :nullify,
           inverse_of: :merchant

  validates :reference, presence: true, uniqueness: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :live_on, presence: true
  validates :disbursement_frequency,
            presence: true,
            inclusion: {
              in: %w[DAILY WEEKLY]
            }
  validates :minimum_monthly_fee, numericality: { greater_than_or_equal_to: 0 }
end
