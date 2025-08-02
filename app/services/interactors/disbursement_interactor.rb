# typed: strict
module Interactors
  class DisbursementInteractor
    extend T::Sig

    sig { params(merchant: Merchant, orders: T::Array[Order]).void }
    def initialize(merchant:, orders:)
      @merchant = merchant
      @orders = orders
    end

    sig { returns(Disbursement) }
    def call
      disbursement = create_disbursement

      create_disbursement_orders(disbursement)
      disbursement
    end

    private

    sig { returns(Disbursement) }
    def create_disbursement
      Disbursement.create!(
        merchant_id: merchant.id,
        frequency: merchant.disbursement_frequency,
        disbursement_date: Date.current,
        total_gross_amount: disbursement_calculator.total_amount,
        total_commission: disbursement_calculator.commission,
        total_net_amount: disbursement_calculator.total_net_amount,
        reference: generate_reference
      )
    end

    sig { params(disbursement: Disbursement).void }
    def create_disbursement_orders(disbursement)
      disbursement_orders =
        orders.map do |order|
          DisbursementOrder.new(disbursement_id: disbursement.id, order_id: order.id)
        end

      DisbursementOrder.import!(
        disbursement_orders,
        on_duplicate_key_ignore: true,
        all_or_none: true,
        validate: false
      )
    end

    sig { returns(String) }
    def generate_reference
      DisbursementReferenceGenerator.call(merchant: merchant, disbursement_date: Date.current)
    end

    sig { returns(DisbursementCalculator::DisbursementBreakdown) }
    def disbursement_calculator
      DisbursementCalculator.new(orders:).call
    end

    sig { returns(Merchant) }
    attr_reader :merchant

    sig { returns(T::Array[Order]) }
    attr_reader :orders
  end
end
