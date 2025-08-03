# typed: strict

class CalculateMonthlyMinimumDefaultsJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(date: Date).void }
  def perform(date: Date.current)
    beginning_of_prev_month = date.last_month.beginning_of_month

    previous_month_commissions = MonthlyMinimumFeeCalculator.new(date: beginning_of_prev_month).call

    defaulting_merchants = previous_month_commissions.select(&:defaulting?)

    defaulting_merchants.each do |merchant_commissions|
      MonthlyMinimumFeeDefault.create!(
        merchant: merchant_commissions.merchant,
        minimum_monthly_fee: merchant_commissions.minimum_monthly_fee,
        actual_commission_paid: merchant_commissions.total_commission,
        defaulted_amount: merchant_commissions.monthly_fee,
        period_date: beginning_of_prev_month
      )
    end
  end
end
