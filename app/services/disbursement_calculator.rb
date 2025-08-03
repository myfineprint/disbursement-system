# typed: strict

class DisbursementCalculator
  extend T::Sig

  class DisbursementBreakdown < T::Struct
    const :commission, BigDecimal
    const :total_net_amount, BigDecimal
    const :total_amount, BigDecimal
  end

  sig { params(orders: T::Array[Order]).void }
  def initialize(orders:)
    @orders = orders
  end

  sig { returns(DisbursementBreakdown) }
  def call
    DisbursementBreakdown.new(
      commission: total_commission,
      total_net_amount:,
      total_amount: total_order_amount
    )
  end

  private

  sig { returns(BigDecimal) }
  def total_commission
    round_to_2_decimal_places(orders.sum { |order| CommissionCalculator.new(order:).call }.to_d)
  end

  sig { returns(BigDecimal) }
  def total_order_amount
    round_to_2_decimal_places(orders.sum(&:amount).to_d)
  end

  sig { returns(BigDecimal) }
  def total_net_amount
    round_to_2_decimal_places((total_order_amount - total_commission).to_d)
  end

  sig { params(value: BigDecimal).returns(BigDecimal) }
  def round_to_2_decimal_places(value)
    BigDecimal(value.to_s).round(2)
  end

  sig { returns(T::Array[Order]) }
  attr_reader :orders
end
