# typed: strict

class MonthlyMinimumFeeCalculator
  extend T::Sig

  class MerchantCommissions < T::Struct
    extend T::Sig

    const :merchant, Merchant
    const :commissions, T::Array[Commission]

    sig { returns(BigDecimal) }
    def total_commission
      round_to_2_decimal_places(commissions.sum(&:commission_amount).to_f)
    end

    sig { returns(BigDecimal) }
    def minimum_monthly_fee
      merchant.minimum_monthly_fee.to_d
    end

    sig { returns(BigDecimal) }
    def monthly_fee_shortfall
      round_to_2_decimal_places((minimum_monthly_fee - total_commission).to_f)
    end

    sig { returns(BigDecimal) }
    def monthly_fee
      monthly_fee_shortfall.positive? ? monthly_fee_shortfall : 0.to_d
    end

    sig { returns(T::Boolean) }
    def defaulting?
      monthly_fee_shortfall.positive?
    end

    sig { params(value: Float).returns(BigDecimal) }
    def round_to_2_decimal_places(value)
      RoundToTwoDecimals.new.call(value)
    end
  end

  sig { params(date: Date).void }
  def initialize(date:)
    @date = date
  end

  sig { returns(T::Array[MerchantCommissions]) }
  def call
    build_merchant_commissions
  end

  private

  sig { returns(T::Array[MerchantCommissions]) }
  def build_merchant_commissions
    grouped_commissions = previous_month_commissions.group_by(&:merchant)

    grouped_commissions.map do |merchant, commissions|
      MerchantCommissions.new(merchant:, commissions:)
    end
  end

  sig { returns(ActiveRecord::Relation) }
  def previous_month_commissions
    month_start = date.beginning_of_month
    month_end = date.end_of_month

    Commission.where(commission_date: month_start..month_end).includes(:order)
  end

  sig { returns(Date) }
  attr_reader :date
end
