# typed: strict

class ProcessMerchantOrdersJob < ApplicationJob
  extend T::Sig

  sig { params(merchant_references: T::Array[String]).void }
  def perform(merchant_references:)
    merchants = Merchant.by_reference(merchant_references)

    if merchants.nil?
      Rails.logger.error("Merchants not found for references: #{merchant_references.join(', ')}")
      return
    end

    merchants
      .includes(:orders)
      .find_each do |merchant|
        if merchant.daily_disbursement?
          eligible_daily_orders =
            merchant.orders.eligible_for_daily_disbursement(Date.current).not_disbursed.to_a

          DailyDisbursement.new(
            merchant: merchant,
            orders: eligible_daily_orders,
            date: Date.current
          ).call
        elsif merchant.weekly_disbursement?
          eligible_weekly_orders =
            merchant.orders.eligible_for_weekly_disbursement(Date.current).not_disbursed.to_a

          WeeklyDisbursement.new(
            merchant: merchant,
            orders: eligible_weekly_orders,
            date: Date.current
          ).call
        end
      end
  end
end
