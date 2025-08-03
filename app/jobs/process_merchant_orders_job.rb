# typed: strict

class ProcessMerchantOrdersJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(merchant: Merchant, date: Date).void }
  def perform(merchant:, date:)
    if merchant.daily_disbursement?
      eligible_daily_orders =
        merchant.orders.eligible_for_daily_disbursement(date).not_disbursed.to_a

      Interactors::DisbursementInteractor.new(
        merchant: merchant,
        orders: eligible_daily_orders,
        date:
      ).call
    elsif merchant.weekly_disbursement?
      eligible_weekly_orders =
        merchant.orders.eligible_for_weekly_disbursement(date).not_disbursed.to_a

      # Only process if it's the merchant's live-on weekday
      return unless date.wday == T.must(merchant.live_on).wday

      Interactors::DisbursementInteractor.new(
        merchant: merchant,
        orders: eligible_weekly_orders,
        date:
      ).call
    end
  end
end
