# typed: strict
module Interactors
  class DisbursementInteractor
    extend T::Sig

    sig { params(merchant: Merchant, orders: T::Array[Order], date: Date).void }
    def initialize(merchant:, orders:, date:)
      @merchant = merchant
      @orders = orders
      @date = date
    end

    sig { returns(Disbursement) }
    def call
      create_disbursement_with_commissions
    end

    private

    sig { returns(Disbursement) }
    def create_disbursement_with_commissions
      ActiveRecord::Base.transaction do
        disbursement = create_disbursement
        Interactors::CommissionInteractor.new(disbursement: disbursement, orders: orders).call

        disbursement
      end
    end

    sig { returns(Disbursement) }
    def create_disbursement
      Disbursement.create!(
        merchant_id: merchant.id,
        frequency: merchant.disbursement_frequency,
        disbursement_date: date,
        total_gross_amount: disbursement_calculator.total_amount,
        total_commission: disbursement_calculator.commission,
        total_net_amount: disbursement_calculator.total_net_amount,
        reference: generate_reference
      )
    end

    sig { returns(String) }
    def generate_reference
      DisbursementReferenceGenerator.call(merchant: merchant, disbursement_date: date)
    end

    sig { returns(DisbursementCalculator::DisbursementBreakdown) }
    def disbursement_calculator
      DisbursementCalculator.new(orders:).call
    end

    sig { returns(Merchant) }
    attr_reader :merchant

    sig { returns(T::Array[Order]) }
    attr_reader :orders

    sig { returns(Date) }
    attr_reader :date
  end
end
