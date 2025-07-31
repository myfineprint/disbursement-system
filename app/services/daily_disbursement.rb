# typed: strict

class DailyDisbursementService
  extend T::Sig

  sig { params(merchant: Merchant, orders: T::Array[Order]).void }
  def initialize(merchant:, orders:)
    @merchant = merchant
    @orders = T.let(orders, T::Array[Order])
  end

  sig { returns(NilClass) }
  def call
  end

  private

  sig { returns(Merchant) }
  attr_reader :merchant

  sig { returns(T::Array[Order]) }
  attr_reader :orders
end
