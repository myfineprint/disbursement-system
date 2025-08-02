# typed: strict

class DailyDisbursement
  extend T::Sig

  sig { params(merchant: Merchant, orders: T::Array[Order], date: Date).void }
  def initialize(merchant:, orders:, date:)
    @merchant = merchant
    @orders = T.let(orders, T::Array[Order])
    @date = date
  end

  sig { returns(Disbursement) }
  def call
    Interactors::DisbursementInteractor.new(merchant:, orders:, date: date).call
  end

  private

  sig { returns(Merchant) }
  attr_reader :merchant

  sig { returns(T::Array[Order]) }
  attr_reader :orders

  sig { returns(Date) }
  attr_reader :date
end
