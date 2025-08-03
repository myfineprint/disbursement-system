# typed: false

require 'rails_helper'

RSpec.describe Interactors::CommissionInteractor do
  let(:merchant) { create(:merchant, reference: 'test_merchant') }
  let(:disbursement) { create(:disbursement, merchant: merchant) }
  let(:orders) do
    [
      create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 25.00), # 1.00% rate
      create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 150.00) # 0.95% rate
    ]
  end

  let(:commission_interactor) { described_class.new(disbursement: disbursement, orders: orders) }

  describe '#call' do
    it 'creates commission records for each order' do
      result = commission_interactor.call

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to be_a(Commission)
      expect(result.last).to be_a(Commission)
    end

    it 'sets correct commission amounts and rates' do
      result = commission_interactor.call

      # First order: 25.00 * 0.01 = 0.25
      first_commission = result.find { |c| c.order_id == orders.first.id }
      expect(first_commission.commission_amount).to eq(0.25)
      expect(first_commission.commission_rate).to eq(0.01)

      # Second order: 150.00 * 0.0095 = 1.425, rounded to 1.43
      second_commission = result.find { |c| c.order_id == orders.last.id }
      expect(second_commission.commission_amount).to eq(1.43)
      expect(second_commission.commission_rate).to eq(0.0095)
    end

    it 'associates commissions with the correct disbursement' do
      result = commission_interactor.call

      result.each do |commission|
        expect(commission.disbursement_id).to eq(disbursement.id)
        expect(commission.disbursement).to eq(disbursement)
      end
    end

    it 'associates commissions with the correct orders' do
      result = commission_interactor.call

      result.each { |commission| expect(orders).to include(commission.order) }
    end

    context 'with different commission rate tiers' do
      let(:orders) do
        [
          create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 25.00), # 1.00% rate
          create(
            :order,
            merchant: merchant,
            merchant_reference: merchant.reference,
            amount: 150.00
          ), # 0.95% rate
          create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 500.00) # 0.85% rate
        ]
      end

      it 'applies correct commission rates for each tier' do
        result = commission_interactor.call

        # Below 50€: 1.00%
        below_50_commission = result.find { |c| c.order.amount == BigDecimal('25.00') }
        expect(below_50_commission.commission_rate).to eq(0.01)

        # Between 50€ and 300€: 0.95%
        between_50_300_commission = result.find { |c| c.order.amount == BigDecimal('150.00') }
        expect(between_50_300_commission.commission_rate).to eq(0.0095)

        # Above 300€: 0.85%
        above_300_commission = result.find { |c| c.order.amount == BigDecimal('500.00') }
        expect(above_300_commission.commission_rate).to eq(0.0085)
      end
    end

    context 'with zero amount orders' do
      let(:orders) do
        [create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 0.00)]
      end

      it 'creates commission with zero amount' do
        result = commission_interactor.call

        expect(result.first.commission_amount).to eq(0.0)
        expect(result.first.commission_rate).to eq(0.01) # Default rate for amounts below 50
      end
    end

    context 'with empty orders array' do
      let(:orders) { [] }

      it 'returns empty array' do
        result = commission_interactor.call

        expect(result).to eq([])
      end
    end
  end
end
