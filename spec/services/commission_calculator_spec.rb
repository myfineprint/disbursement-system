# typed: false

require 'rails_helper'

RSpec.describe CommissionCalculator do
  describe '#call' do
    context 'when order amount is below 50' do
      let(:order) { build(:order, amount: 25.00) }
      let(:calculator) { described_class.new(order:) }

      it 'applies 1% commission rate' do
        result = calculator.call
        # 25.00 * 0.01 = 0.25
        expect(result).to eq(BigDecimal('0.25'))
      end
    end

    context 'when order amount is between 50 and 300' do
      let(:order) { build(:order, amount: 150.00) }
      let(:calculator) { described_class.new(order:) }

      it 'applies 0.95% commission rate' do
        result = calculator.call
        # 150.00 * 0.0095 = 1.425
        expect(result).to eq(BigDecimal('1.425'))
      end
    end

    context 'when order amount is 300 or above' do
      let(:order) { build(:order, amount: 500.00) }
      let(:calculator) { described_class.new(order:) }

      it 'applies 0.85% commission rate' do
        result = calculator.call
        # 500.00 * 0.0085 = 4.25
        expect(result).to eq(BigDecimal('4.25'))
      end
    end

    context 'with edge cases' do
      it 'handles amount exactly at 50' do
        order = build(:order, amount: 50.00)
        calculator = described_class.new(order:)
        result = calculator.call
        # 50.00 * 0.0095 = 0.475 (uses Between50And300 rate)
        expect(result).to eq(BigDecimal('0.475'))
      end

      it 'handles amount exactly at 300' do
        order = build(:order, amount: 300.00)
        calculator = described_class.new(order:)
        result = calculator.call
        # 300.00 * 0.0085 = 2.55 (uses Above300 rate)
        expect(result).to eq(BigDecimal('2.55'))
      end

      it 'handles amount just below 50' do
        order = build(:order, amount: 49.99)
        calculator = described_class.new(order:)
        result = calculator.call
        # 49.99 * 0.01 = 0.4999
        expect(result).to eq(BigDecimal('0.4999'))
      end

      it 'handles amount just below 300' do
        order = build(:order, amount: 299.99)
        calculator = described_class.new(order:)
        result = calculator.call
        # 299.99 * 0.0095 = 2.849905
        expect(result).to eq(BigDecimal('2.849905'))
      end
    end

    context 'with decimal precision' do
      it 'handles decimal amounts correctly' do
        order = build(:order, amount: 123.45)
        calculator = described_class.new(order:)
        result = calculator.call
        # 123.45 * 0.0095 = 1.172775
        expect(result).to eq(BigDecimal('1.172775'))
      end

      it 'handles zero amount' do
        order = build(:order, amount: 0.00)
        calculator = described_class.new(order:)
        result = calculator.call
        # 0.00 * 0.01 = 0.00
        expect(result).to eq(BigDecimal('0.00'))
      end
    end

    context 'with different data types' do
      it 'handles string amounts' do
        order = build(:order, amount: '75.50')
        calculator = described_class.new(order:)
        result = calculator.call
        # 75.50 * 0.0095 = 0.71725
        expect(result).to eq(BigDecimal('0.71725'))
      end

      it 'handles integer amounts' do
        order = build(:order, amount: 200)
        calculator = described_class.new(order:)
        result = calculator.call
        # 200 * 0.0095 = 1.9
        expect(result).to eq(BigDecimal('1.9'))
      end
    end
  end
end
