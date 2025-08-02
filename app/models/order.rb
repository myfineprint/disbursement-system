# typed: strict

class Order < ApplicationRecord
  extend T::Sig

  belongs_to :merchant,
             foreign_key: 'merchant_reference',
             primary_key: 'reference',
             inverse_of: :orders
  has_one :commission, dependent: :destroy
  has_one :disbursement, through: :commission

  validates :merchant_reference, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :created_at, presence: true

  scope :eligible_for_daily_disbursement,
        lambda { |date = Date.current|
          joins(:merchant).where(merchants: { live_on: ..date }).where(
            created_at: date.yesterday.all_day
          )
        }

  scope :eligible_for_weekly_disbursement,
        lambda { |date = Date.current|
          joins(:merchant).where(merchants: { live_on: ..date }).where(
            created_at: previous_week_range(date)
          )
        }

  scope :not_disbursed, -> { where.missing(:commission) }

  # Returns the previous week range (Saturday to Friday)
  # If date is Sat, 02 Aug 2025, returns Sat, 26 Jul 2025..Fri, 01 Aug 2025
  sig { params(date: Date).returns(T::Range[Date]) }
  def self.previous_week_range(date)
    last_week_start = (date - 7.days).beginning_of_day
    last_week_end = date.yesterday.end_of_day

    last_week_start..last_week_end
  end
end
