# typed: strict

class DisbursementProcessingJob < ApplicationJob
  extend T::Sig

  BATCH_SIZE = 1000
  TODAY = T.let(Date.current, Date)

  queue_as :default

  sig { void }
  def perform
    eligible_orders_to_process =
      Order.eligible_for_disbursement(TODAY).not_disbursed.includes(:merchant)

    eligible_orders_to_process.in_batches(of: BATCH_SIZE) do |batch|
      grouped_merchant = batch.group_by(&:merchant)
      grouped_merchant.each do |merchant, orders|
        if merchant.nil?
          Rails.logger.error(
            "Merchant not found for orders: #{orders.map(&:id).join(', ')}"
          )
          next
        end

        if merchant.daily_disbursement?
          DailyDisbursement.new(merchant: merchant, orders:).call
        elsif merchant.weekly_disbursement?
          WeeklyDisbursement.new(merchant: merchant, orders:).call
        end
      end
    end
  end
end
