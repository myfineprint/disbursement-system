# typed: strict

module Interactors
  class CommissionInteractor
    extend T::Sig

    sig { params(disbursement: Disbursement, orders: T::Array[Order]).void }
    def initialize(disbursement:, orders:)
      @disbursement = disbursement
      @orders = orders
    end

    sig { returns(T::Array[Commission]) }
    def call
      create_commission_records
    end

    private

    sig { returns(T::Array[Commission]) }
    def create_commission_records
      commissions =
        orders.map do |order|
          commission_amount = calculate_commission_for_order(order)
          commission_rate = get_commission_rate_for_order(order)

          Commission.new(
            disbursement_id: disbursement.id,
            order_id: order.id,
            commission_amount: commission_amount,
            commission_rate: commission_rate,
            commission_date: disbursement.disbursement_date
          )
        end

      Commission.import!(
        commissions,
        validate: true,
        all_or_none: true,
        on_duplicate_key_ignore: true
      )

      commissions
    end

    sig { params(order: Order).returns(BigDecimal) }
    def calculate_commission_for_order(order)
      round_to_2_decimal_places(order.amount.to_d * get_commission_rate_for_order(order))
    end

    sig { params(order: Order).returns(BigDecimal) }
    def get_commission_rate_for_order(order)
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

    sig { params(value: BigDecimal).returns(BigDecimal) }
    def round_to_2_decimal_places(value)
      RoundToTwoDecimals.new.call(value)
    end

    sig { returns(Disbursement) }
    attr_reader :disbursement

    sig { returns(T::Array[Order]) }
    attr_reader :orders
  end
end
