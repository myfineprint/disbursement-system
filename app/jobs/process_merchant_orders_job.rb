# typed: strict

class ProcessMerchantOrdersJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(merchant: Merchant, date: Date).void }
  def perform(merchant:, date:)
    if merchant.daily_disbursement?
      eligible_daily_orders =
        merchant.orders.eligible_for_daily_disbursement(date).not_disbursed.to_a

      return if eligible_daily_orders.empty?

      Interactors::DisbursementInteractor.new(
        merchant: merchant,
        orders: eligible_daily_orders,
        date:
      ).call
    elsif merchant.weekly_disbursement?
      eligible_weekly_orders =
        merchant.orders.eligible_for_weekly_disbursement(date).not_disbursed.to_a

      return if date.wday != T.must(merchant.live_on).wday

      return if eligible_weekly_orders.empty?

      Interactors::DisbursementInteractor.new(
        merchant: merchant,
        orders: eligible_weekly_orders,
        date:
      ).call
    end
  end
end
