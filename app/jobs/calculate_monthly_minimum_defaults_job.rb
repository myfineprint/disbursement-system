# typed: strict

class CalculateMonthlyMinimumDefaultsJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(date: Date).void }
  def perform(date: Date.current)
    beginning_of_prev_month = date.last_month.beginning_of_month

    previous_month_commissions = MonthlyMinimumFeeCalculator.new(date: beginning_of_prev_month).call

    defaulting_merchants = previous_month_commissions.select(&:defaulting?)

    defaulting_merchants.each do |merchant_commission|
      MonthlyMinimumFeeDefault.create!(
        merchant: merchant_commission.merchant,
        minimum_monthly_fee: merchant_commission.minimum_monthly_fee,
        actual_commission_paid: merchant_commission.total_commission,
        defaulted_amount: merchant_commission.monthly_fee,
        period_date: beginning_of_prev_month
      )
    end
  end
end
