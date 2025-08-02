# typed: strict

class Disbursement < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :merchant, class_name: 'Merchant', optional: false
  has_many :disbursement_orders,
           class_name: 'DisbursementOrder',
           dependent: :destroy
  has_many :orders, class_name: 'Order', through: :disbursement_orders

  # Validations
  validates :frequency,
            presence: true,
            inclusion: {
              in: Enums::DisbursementFrequency.values.map(&:serialize)
            }
  validates :disbursement_date, presence: true
  validates :total_gross_amount,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0
            }
  validates :total_commission,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0
            }
  validates :total_net_amount,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0
            }
  validates :reference, presence: true

  # Scopes
  scope :daily,
        lambda {
          where(frequency: Enums::DisbursementFrequency::Daily.serialize)
        }
  scope :weekly,
        lambda {
          where(frequency: Enums::DisbursementFrequency::Weekly.serialize)
        }
  scope :for_date, ->(date) { where(disbursement_date: date) }
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }

  # Callbacks
  before_validation :generate_reference, on: :create

  private

  sig { void }
  def generate_reference
    return if reference.present?

    loop do
      self.reference = "DISB#{SecureRandom.alphanumeric(8).upcase}"
      break unless Disbursement.exists?(reference: reference)
    end
  end
end
