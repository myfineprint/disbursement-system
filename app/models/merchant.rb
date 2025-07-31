# typed: strict

class Merchant < ApplicationRecord
  extend T::Sig

  has_many :orders,
           class_name: 'Order',
           foreign_key: 'merchant_reference',
           primary_key: 'reference',
           dependent: :nullify,
           inverse_of: :merchant
  class Frequency < T::Enum
    extend T::Sig

    enums do
      Daily = new('DAILY')
      Weekly = new('WEEKLY')
    end

    sig { returns(T::Boolean) }
    def daily?
      self == Daily
    end

    sig { returns(T::Boolean) }
    def weekly?
      self == Weekly
    end
  end

  validates :reference, presence: true, uniqueness: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :live_on, presence: true
  validates :disbursement_frequency,
            presence: true,
            inclusion: {
              in: Frequency.values.map(&:to_s)
            }
  validates :minimum_monthly_fee, numericality: { greater_than_or_equal_to: 0 }

  scope :live_as_of, ->(date = Date.current) { where(live_on: ..date) }
  scope :daily_disbursement, -> { where(disbursement_frequency: 'DAILY') }
  scope :weekly_disbursement, -> { where(disbursement_frequency: 'WEEKLY') }

  sig { returns(T::Boolean) }
  def daily_disbursement?
    Frequency.deserialize(disbursement_frequency).daily?
  end

  sig { returns(T::Boolean) }
  def weekly_disbursement?
    Frequency.deserialize(disbursement_frequency).weekly?
  end
end
