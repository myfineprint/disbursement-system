# typed: strict

class DisbursementCalculator
  extend T::Sig

  class DisbursementBreakdown < T::Struct
    const :commission, Float
    const :total_net_amount, Float
    const :total_amount, Float
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

  sig { returns(Float) }
  def total_commission
    round_to_2_decimal_places(orders.sum { |order| CommissionCalculator.new(order:).call }.to_f)
  end

  sig { returns(Float) }
  def total_order_amount
    round_to_2_decimal_places(orders.sum(&:amount).to_f)
  end

  sig { returns(Float) }
  def total_net_amount
    round_to_2_decimal_places(total_order_amount - total_commission)
  end

  sig { params(value: Float).returns(Float) }
  def round_to_2_decimal_places(value)
    value.round(2).to_f
  end

  sig { returns(T::Array[Order]) }
  attr_reader :orders
end
