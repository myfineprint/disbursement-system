# typed: strict

class CommissionCalculator
  extend T::Sig

  sig { params(order: Order).void }
  def initialize(order:)
    @order = order
  end

  sig { returns(BigDecimal) }
  def call
    order.amount.to_d * commission_rate_for_order(order)
  end

  private

  sig { params(order: Order).returns(BigDecimal) }
  def commission_rate_for_order(order)
    amount = order.amount.to_d

    case amount
    when 0...50
      Enums::CommissionRates::Below50.serialize
    when 50...300
      Enums::CommissionRates::Between50And300.serialize
    else
      Enums::CommissionRates::Above300.serialize
    end
  end

  sig { returns(Order) }
  attr_reader :order
end
