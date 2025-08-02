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
        eligible_orders = merchant.orders.eligible_for_disbursement(Date.current).not_disbursed.to_a

        if merchant.daily_disbursement?
          DailyDisbursement.new(merchant: merchant, orders: eligible_orders).call
        elsif merchant.weekly_disbursement?
          WeeklyDisbursement.new(
            merchant: merchant,
            orders: eligible_orders,
            date: Date.current
          ).call
        end
      end
  end
end
