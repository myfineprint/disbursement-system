# typed: strict

class DisbursementCalculator
  extend T::Sig

  class DisbursementBreakdown < T::Struct
    extend T::Sig

    const :commission, BigDecimal
    const :total_net_amount, BigDecimal
    const :total_amount, BigDecimal

    sig { returns(T::Boolean) }
    def to_be_disbursed?
      commission.positive? && total_net_amount.positive? && total_amount.positive?
    end
  end

  sig { params(orders: T::Array[Order]).void }
  def initialize(orders:)
    @orders = orders
  end

  sig { returns(DisbursementBreakdown) }
  def call
    DisbursementBreakdown.new(
      commission: round_to_2_decimal_places(total_commission),
      total_net_amount: round_to_2_decimal_places(total_net_amount),
      total_amount: round_to_2_decimal_places(total_order_amount)
    )
  end

  private

  sig { returns(Float) }
  def total_commission
    orders.sum { |order| CommissionCalculator.new(order:).call }.to_f
  end

  sig { returns(Float) }
  def total_order_amount
    orders.sum(&:amount).to_f
  end

  sig { returns(Float) }
  def total_net_amount
    (total_order_amount - total_commission).to_f
  end

  sig { params(value: Float).returns(BigDecimal) }
  def round_to_2_decimal_places(value)
    RoundToTwoDecimals.new.call(value)
  end

  sig { returns(T::Array[Order]) }
  attr_reader :orders
end
