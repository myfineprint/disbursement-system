# typed: strict

class WeeklyDisbursement
  extend T::Sig

  sig { params(merchant: Merchant, orders: T::Array[Order], date: Date).void }
  def initialize(merchant:, orders:, date:)
    @merchant = merchant
    @orders = orders
    @date = date
  end

  sig { returns(T.nilable(Disbursement)) }
  def call
    weekday = date.wday

    merchant_live_on_weekday = T.must(merchant.live_on).wday

    return if weekday != merchant_live_on_weekday

    Interactors::DisbursementInteractor.new(merchant:, orders:).call
  end

  private

  sig { returns(Merchant) }
  attr_reader :merchant

  sig { returns(T::Array[Order]) }
  attr_reader :orders

  sig { returns(Date) }
  attr_reader :date
end
