# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DisbursementCalculator do
  let(:merchant) { create(:merchant) }

  describe '#call' do
    it 'returns a DisbursementBreakdown struct' do
      orders = [create(:order, merchant_reference: merchant.reference, amount: 100)]
      calculator = described_class.new(orders: orders)

      result = calculator.call

      expect(result).to be_a(DisbursementCalculator::DisbursementBreakdown)
      expect(result.commission).to be_a(BigDecimal)
      expect(result.total_net_amount).to be_a(BigDecimal)
      expect(result.total_amount).to be_a(BigDecimal)

      # Verify actual values for the test case
      # 100.00 * 0.0095 = 0.95 (0.95% rate for amounts between 50€ and 300€)
      expect(result.commission).to eq(0.95)
      expect(result.total_amount).to eq(100.00)
      expect(result.total_net_amount).to eq(99.05) # 100.00 - 0.95
    end
  end

  describe 'commission rate calculations' do
    context 'when order amount is below 50€' do
      it 'applies 1.00% commission rate' do
        order = create(:order, merchant_reference: merchant.reference, amount: 25.50)
        calculator = described_class.new(orders: [order])

        result = calculator.call

        # 25.50 * 0.01 = 0.255, rounded up to 0.26
        expect(result.commission).to eq(0.26)
        expect(result.total_amount).to eq(25.50)
        expect(result.total_net_amount).to eq(25.24) # 25.50 - 0.26
      end
    end

    context 'when order amount is between 50€ and 300€' do
      it 'applies 0.95% commission rate' do
        order = create(:order, merchant_reference: merchant.reference, amount: 150.00)
        calculator = described_class.new(orders: [order])

        result = calculator.call

        # 150.00 * 0.0095 = 1.425, rounded up to 1.43
        expect(result.commission).to eq(1.43)
        expect(result.total_amount).to eq(150.00)
        expect(result.total_net_amount).to eq(148.57) # 150.00 - 1.43
      end
    end

    context 'when order amount is 300€ or more' do
      it 'applies 0.85% commission rate' do
        order = create(:order, merchant_reference: merchant.reference, amount: 500.00)
        calculator = described_class.new(orders: [order])

        result = calculator.call

        # 500.00 * 0.0085 = 4.25, rounded up to 4.25
        expect(result.commission).to eq(4.25)
        expect(result.total_amount).to eq(500.00)
        expect(result.total_net_amount).to eq(495.75) # 500.00 - 4.25
      end
    end
  end

  describe 'rounding behavior' do
    it 'always rounds up commission to up to 2 decimal places' do
      # Test edge cases where rounding is needed
      test_cases = [
        { amount: 1.00, expected_commission: 0.01 }, # 1.00 * 0.01 = 0.01
        { amount: 1.50, expected_commission: 0.02 }, # 1.50 * 0.01 = 0.015, rounded up to 0.02
        { amount: 50.00, expected_commission: 0.48 }, # 50.00 * 0.0095 = 0.475, rounded up to 0.48
        { amount: 100.00, expected_commission: 0.95 }, # 100.00 * 0.0095 = 0.95
        { amount: 300.00, expected_commission: 2.55 }, # 300.00 * 0.0085 = 2.55
        { amount: 301.01, expected_commission: 2.56 } # 301.01 * 0.0085 = 2.558585, rounded up to 2.56
      ]

      test_cases.each do |test_case|
        order = create(:order, merchant_reference: merchant.reference, amount: test_case[:amount])
        calculator = described_class.new(orders: [order])

        result = calculator.call

        expect(result.commission).to eq(test_case[:expected_commission])
      end
    end
  end

  describe 'multiple orders' do
    it 'calculates commission for multiple orders with different rates' do
      orders = [
        create(:order, merchant_reference: merchant.reference, amount: 25.00), # 1.00% rate
        create(:order, merchant_reference: merchant.reference, amount: 150.00), # 0.95% rate
        create(:order, merchant_reference: merchant.reference, amount: 400.00) # 0.85% rate
      ]

      calculator = described_class.new(orders: orders)
      result = calculator.call

      # Expected calculations:
      # Order 1: 25.00 * 0.01 = 0.25
      # Order 2: 150.00 * 0.0095 = 1.425, rounded up to 1.43
      # Order 3: 400.00 * 0.0085 = 3.4
      # Total commission: 0.25 + 1.43 + 3.4 = 5.08
      # Total amount: 25.00 + 150.00 + 400.00 = 575.00
      # Net amount: 575.00 - 5.08 = 569.92

      expect(result.commission).to eq(5.08)
      expect(result.total_amount).to eq(575.00)
      expect(result.total_net_amount).to eq(569.92)
    end
  end

  describe 'edge cases' do
    context 'with zero amount orders' do
      it 'handles zero amounts correctly' do
        order = create(:order, merchant_reference: merchant.reference, amount: 0.00)
        calculator = described_class.new(orders: [order])

        result = calculator.call

        # 0.00 * any_rate = 0.00
        expect(result.commission).to eq(0.0)
        expect(result.total_amount).to eq(0.0)
        expect(result.total_net_amount).to eq(0.0) # 0.0 - 0.0
      end
    end

    context 'with empty orders array' do
      it 'returns zero values' do
        calculator = described_class.new(orders: [])

        result = calculator.call

        expect(result.commission).to eq(0.0)
        expect(result.total_amount).to eq(0.0)
        expect(result.total_net_amount).to eq(0.0)
      end
    end

    context 'with very small amounts' do
      it 'handles small amounts correctly' do
        order = create(:order, merchant_reference: merchant.reference, amount: 0.01)
        calculator = described_class.new(orders: [order])

        result = calculator.call

        # 0.01 * 0.01 = 0.0001, but minimum commission is 0.00 for very small amounts
        expect(result.commission).to eq(0.00)
        expect(result.total_amount).to eq(0.01)
        expect(result.total_net_amount).to eq(0.01) # 0.01 - 0.00
      end
    end
  end
end
