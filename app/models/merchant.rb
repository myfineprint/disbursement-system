# typed: strict

class Merchant < ApplicationRecord
  extend T::Sig

  has_many :orders,
           class_name: 'Order',
           foreign_key: 'merchant_reference',
           primary_key: 'reference',
           dependent: :nullify,
           inverse_of: :merchant
  has_many :disbursements, dependent: :destroy
  has_many :commissions, through: :orders
  has_many :monthly_minimum_fee_defaults, dependent: :destroy

  validates :reference, presence: true, uniqueness: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :live_on, presence: true
  validates :disbursement_frequency,
            presence: true,
            inclusion: {
              in: Enums::DisbursementFrequency.values.map(&:serialize)
            }
  validates :minimum_monthly_fee, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :by_reference, ->(reference) { where(reference:) }
  scope :live_as_of, ->(date = Date.current) { where(live_on: ..date) }
  scope :daily_disbursement,
        -> { where(disbursement_frequency: Enums::DisbursementFrequency::Daily.serialize) }
  scope :weekly_disbursement,
        -> { where(disbursement_frequency: Enums::DisbursementFrequency::Weekly.serialize) }

  sig { returns(T::Boolean) }
  def daily_disbursement?
    Enums::DisbursementFrequency.deserialize(disbursement_frequency).daily?
  end

  sig { returns(T::Boolean) }
  def weekly_disbursement?
    Enums::DisbursementFrequency.deserialize(disbursement_frequency).weekly?
  end
end
