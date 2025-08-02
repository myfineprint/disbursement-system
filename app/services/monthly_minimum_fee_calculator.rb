# typed: strict

class MonthlyMinimumFeeCalculator
  extend T::Sig

  class MerchantCommissions < T::Struct
    extend T::Sig

    const :merchant, Merchant
    const :commissions, T::Array[Commission]

    sig { returns(Float) }
    def total_commission
      commissions.sum(&:commission_amount).to_f
    end

    sig { returns(Float) }
    def monthly_fee_shortfall
      total_commission - merchant.minimum_monthly_fee.to_f
    end

    sig { returns(Float) }
    def monthly_fee
      monthly_fee_shortfall.negative? ? monthly_fee_shortfall.abs : 0.0
    end

    sig { returns(T::Boolean) }
    def defaulting?
      monthly_fee_shortfall.negative?
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

  sig { returns(Commission::PrivateRelation) }
  def previous_month_commissions
    previous_month = date.prev_month
    previous_month_start = previous_month.beginning_of_month
    previous_month_end = previous_month.end_of_month

    Commission.where(created_at: previous_month_start..previous_month_end).includes(:merchant)
  end

  sig { returns(Date) }
  attr_reader :date
end
