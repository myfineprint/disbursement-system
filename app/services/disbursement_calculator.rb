# typed: strict

class DisbursementCalculator
  extend T::Sig

  class CommissionRates < T::Enum
    enums do
      Below50 = new(0.01)
      Between50And300 = new(0.0095)
      Above300 = new(0.0085)
    end
  end

  class DisbursementBreakdown < T::Struct
    const :commission, Float
    const :total_net_amount, Float
    const :total_amount, Float
  end

  sig { params(orders: T::Array[Order]).void }
  def initialize(orders:)
    @orders = T.let(orders, T::Array[Order])
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
    round_to_2_decimal_places(
      orders.sum { |order| commission_per_order(order) }.to_f
    )
  end

  sig { params(order: Order).returns(Float) }
  def commission_per_order(order)
    order.amount.to_f * commission_rate_for_order(order)
  end

  sig { returns(Float) }
  def total_order_amount
    round_to_2_decimal_places(orders.sum(&:amount).to_f)
  end

  sig { returns(Float) }
  def total_net_amount
    round_to_2_decimal_places(total_order_amount - total_commission)
  end

  sig { params(order: Order).returns(Float) }
  def commission_rate_for_order(order)
    amount = order.amount.to_f

    case amount
    when 0...50
      CommissionRates::Below50.serialize
    when 50...300
      CommissionRates::Between50And300.serialize
    else
      CommissionRates::Above300.serialize
    end
  end

  sig { params(value: Float).returns(Float) }
  def round_to_2_decimal_places(value)
    value.round(2).to_f
  end

  sig { returns(T::Array[Order]) }
  attr_reader :orders
end
