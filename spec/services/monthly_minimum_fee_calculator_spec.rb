# typed: false

require 'rails_helper'

RSpec.describe MonthlyMinimumFeeCalculator do
  let(:date) { Date.new(2025, 7, 1) }
  let(:calculation_month) { date.all_month }

  around { |example| Timecop.freeze(date) { example.run } }

  describe '#call' do
    let!(:merchant1) { create(:merchant, minimum_monthly_fee: 100.00) }
    let!(:merchant2) { create(:merchant, minimum_monthly_fee: 50.00) }
    let!(:merchant3) { create(:merchant, minimum_monthly_fee: 200.00) }

    context 'when merchants have commissions in the calculation month' do
      let!(:commission1) do
        create(
          :commission,
          order: create(:order, merchant_reference: merchant1.reference),
          commission_amount: 75.00,
          commission_date: date.beginning_of_month + 1.day
        )
      end
      let!(:commission2) do
        create(
          :commission,
          order: create(:order, merchant_reference: merchant1.reference),
          commission_amount: 25.00,
          commission_date: date.beginning_of_month + 15.days
        )
      end
      let!(:commission3) do
        create(
          :commission,
          order: create(:order, merchant_reference: merchant2.reference),
          commission_amount: 60.00,
          commission_date: date.end_of_month - 1.day
        )
      end

      let(:subject) { described_class.new(date:) }

      it 'returns merchant commissions for the calculation month' do
        result = subject.call

        expect(result.length).to eq(2)
        expect(result.map(&:merchant)).to match_array([merchant1, merchant2])
      end

      it 'calculates correct total commission for each merchant' do
        result = subject.call

        merchant1_result = result.find { |r| r.merchant == merchant1 }
        merchant2_result = result.find { |r| r.merchant == merchant2 }

        expect(merchant1_result.total_commission).to eq(BigDecimal('100.00'))
        expect(merchant2_result.total_commission).to eq(BigDecimal('60.00'))
      end

      it 'returns correct minimum monthly fee for each merchant' do
        result = subject.call

        merchant1_result = result.find { |r| r.merchant == merchant1 }
        merchant2_result = result.find { |r| r.merchant == merchant2 }

        expect(merchant1_result.minimum_monthly_fee).to eq(BigDecimal('100.00'))
        expect(merchant2_result.minimum_monthly_fee).to eq(BigDecimal('50.00'))
      end

      it 'calculates correct monthly fee shortfall' do
        result = subject.call

        merchant1_result = result.find { |r| r.merchant == merchant1 }
        merchant2_result = result.find { |r| r.merchant == merchant2 }

        # merchant1: 100.00 - 100.00 = 0.00 (no shortfall)
        expect(merchant1_result.monthly_fee_shortfall).to eq(BigDecimal('0.00'))
        # merchant2: 50.00 - 60.00 = -10.00 (exceeded minimum)
        expect(merchant2_result.monthly_fee_shortfall).to eq(BigDecimal('-10.00'))
      end

      it 'calculates correct monthly fee (only when shortfall is negative)' do
        result = subject.call

        merchant1_result = result.find { |r| r.merchant == merchant1 }
        merchant2_result = result.find { |r| r.merchant == merchant2 }

        # merchant1: no shortfall, so no fee
        expect(merchant1_result.monthly_fee).to eq(BigDecimal('0.00'))
        # merchant2: exceeded minimum, so no fee
        expect(merchant2_result.monthly_fee).to eq(BigDecimal('0.00'))
      end

      it 'correctly identifies merchants that are defaulting' do
        result = subject.call

        merchant1_result = result.find { |r| r.merchant == merchant1 }
        merchant2_result = result.find { |r| r.merchant == merchant2 }

        # merchant1: met minimum, not defaulting
        expect(merchant1_result.defaulting?).to be false
        # merchant2: exceeded minimum, not defaulting
        expect(merchant2_result.defaulting?).to be false
      end
    end

    context 'when merchants have shortfall (need to pay minimum fee)' do
      let!(:commission1) do
        create(
          :commission,
          order: create(:order, merchant_reference: merchant1.reference),
          commission_amount: 75.00,
          commission_date: date.beginning_of_month + 1.day
        )
      end
      let!(:commission3) do
        create(
          :commission,
          order: create(:order, merchant_reference: merchant3.reference),
          commission_amount: 150.00,
          commission_date: date.beginning_of_month + 15.days
        )
      end

      it 'calculates correct monthly fee for merchants with shortfall' do
        result = described_class.new(date:).call

        merchant1_result = result.find { |r| r.merchant == merchant1 }
        merchant3_result = result.find { |r| r.merchant == merchant3 }

        # merchant1: 100.00 - 75.00 = 25.00 shortfall
        expect(merchant1_result.monthly_fee_shortfall).to eq(BigDecimal('25.00'))
        expect(merchant1_result.monthly_fee).to eq(BigDecimal('25.00'))
        expect(merchant1_result.defaulting?).to be true

        # merchant3: 200.00 - 150.00 = 50.00 shortfall
        expect(merchant3_result.monthly_fee_shortfall).to eq(BigDecimal('50.00'))
        expect(merchant3_result.monthly_fee).to eq(BigDecimal('50.00'))
        expect(merchant3_result.defaulting?).to be true
      end
    end

    context 'when merchants have no commissions in the calculation month' do
      it 'returns empty array' do
        result = described_class.new(date:).call

        expect(result).to be_empty
      end
    end

    context 'when commissions exist outside the calculation month' do
      let!(:commission_outside_period) do
        create(
          :commission,
          order: create(:order, merchant_reference: merchant1.reference),
          commission_amount: 100.00,
          commission_date: date.prev_month.beginning_of_month
        )
      end

      it 'excludes commissions from other months' do
        result = described_class.new(date:).call

        expect(result).to be_empty
      end
    end

    context 'with decimal precision' do
      let!(:commission) do
        create(
          :commission,
          order: create(:order, merchant_reference: merchant1.reference),
          commission_amount: 99.999,
          commission_date: date.beginning_of_month + 1.day
        )
      end

      it 'rounds commission amounts to 2 decimal places' do
        result = described_class.new(date:).call
        merchant_result = result.find { |r| r.merchant == merchant1 }

        expect(merchant_result.total_commission).to eq(BigDecimal('100.00'))
        expect(merchant_result.monthly_fee_shortfall).to eq(BigDecimal('0.00'))
        expect(merchant_result.monthly_fee).to eq(BigDecimal('0.00'))
      end
    end

    context 'with different calculation dates' do
      let(:august_date) { Date.new(2025, 8, 15) } # Any date in August
      let!(:july_commission) do
        create(
          :commission,
          order: create(:order, merchant_reference: merchant1.reference),
          commission_amount: 100.00,
          commission_date: date.beginning_of_month + 1.day # July
        )
      end
      let!(:august_commission) do
        create(
          :commission,
          order: create(:order, merchant_reference: merchant1.reference),
          commission_amount: 50.00,
          commission_date: august_date.beginning_of_month + 1.day # August
        )
      end

      it 'calculates for the month of the given date' do
        july_result = described_class.new(date:).call
        august_result = described_class.new(date: august_date).call

        # July calculation should include July commission
        expect(july_result.first.total_commission).to eq(BigDecimal('100.00'))

        # August calculation should include August commission
        expect(august_result.first.total_commission).to eq(BigDecimal('50.00'))
      end
    end
  end
end
