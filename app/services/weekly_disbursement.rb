# typed: strict

class WeeklyDisbursement
  extend T::Sig

  sig { params(merchant: Merchant, orders: T::Array[Order]).void }
  def initialize(merchant:, orders:)
    @merchant = merchant
    @orders = T.let(orders, T::Array[Order])
  end

  sig { returns(T.nilable(Disbursement)) }
  def call
    weekday = Date.current.wday

    merchant_live_on_weekday = T.must(merchant.live_on).wday

    return if weekday != merchant_live_on_weekday

    Interactors::DisbursementInteractor.new(merchant:, orders:).call
  end

  private

  sig { returns(Merchant) }
  attr_reader :merchant

  sig { returns(T::Array[Order]) }
  attr_reader :orders
end
