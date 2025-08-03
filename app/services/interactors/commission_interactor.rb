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
          commission_calculator = commission_for_order(order)
          commission_amount = commission_calculator.call
          commission_rate = commission_calculator.commission_rate_for_order

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
      round_to_2_decimal_places(commission_for_order(order).call)
    end

    sig { params(order: Order).returns(CommissionCalculator) }
    def commission_for_order(order)
      CommissionCalculator.new(order:)
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
