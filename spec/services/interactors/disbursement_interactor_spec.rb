# typed: false

require 'rails_helper'

RSpec.describe Interactors::DisbursementInteractor do
  let(:merchant) do
    create(
      :merchant,
      reference: 'test_merchant',
      disbursement_frequency: Enums::DisbursementFrequency::Daily.serialize
    )
  end

  let(:orders) do
    [
      create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 25.00), # 1.00% rate
      create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 150.00) # 0.95% rate
    ]
  end

  let(:date) { Date.new(2025, 8, 3) }
  let(:disbursement_interactor) do
    described_class.new(merchant: merchant, orders: orders, date: date)
  end

  around { |example| Timecop.freeze(date) { example.run } }

  describe '#call' do
    it 'creates a disbursement record' do
      result = disbursement_interactor.call

      expect(result).to be_a(Disbursement)
      expect(result).to be_persisted
      expect(result.merchant).to eq(merchant)
      expect(result.frequency).to eq(Enums::DisbursementFrequency::Daily.serialize)
      expect(result.disbursement_date).to eq(date)
    end

    it 'calculates correct disbursement amounts' do
      result = disbursement_interactor.call

      # Expected calculations:
      # Order 1: 25.00 * 0.01 = 0.25
      # Order 2: 150.00 * 0.0095 = 1.425, rounded to 1.43
      # Total gross: 25.00 + 150.00 = 175.00
      # Total commission: 0.25 + 1.43 = 1.68
      # Total net: 175.00 - 1.68 = 173.32

      expect(result.total_gross_amount).to eq(BigDecimal('175.00'))
      expect(result.total_commission).to eq(BigDecimal('1.68'))
      expect(result.total_net_amount).to eq(BigDecimal('173.32'))
    end

    it 'generates a valid reference' do
      result = disbursement_interactor.call

      # Expected format: D{day_number}-{merchant_reference}-{date}-{year}
      expected_reference =
        "D#{date.strftime('%d')}-#{merchant.reference}-#{date.strftime('%Y%m%d')}-#{date.year}"
      expect(result.reference).to eq(expected_reference)
    end

    it 'creates commission records for all orders' do
      result = disbursement_interactor.call

      expect(result.commissions.count).to eq(2)
      expect(result.commissions.map(&:order)).to match_array(orders)
    end

    it 'sets correct commission amounts' do
      result = disbursement_interactor.call

      # First order: 25.00 * 0.01 = 0.25
      first_commission = result.commissions.find { |c| c.order.amount == BigDecimal('25.00') }
      expect(first_commission.commission_amount).to eq(BigDecimal('0.25'))
      expect(first_commission.commission_rate).to eq(BigDecimal('0.01'))

      # Second order: 150.00 * 0.0095 = 1.425, rounded to 1.43
      second_commission = result.commissions.find { |c| c.order.amount == BigDecimal('150.00') }
      expect(second_commission.commission_amount).to eq(BigDecimal('1.43'))
      expect(second_commission.commission_rate).to eq(BigDecimal('0.0095'))
    end

    it 'associates commissions with the disbursement' do
      result = disbursement_interactor.call

      result.commissions.each do |commission|
        expect(commission.disbursement).to eq(result)
        expect(commission.disbursement_id).to eq(result.id)
      end
    end
  end

  describe 'transaction behavior' do
    it 'ensures atomicity - rolls back disbursement if commission creation fails' do
      # Mock CommissionInteractor to raise an error
      allow_any_instance_of(Interactors::CommissionInteractor).to receive(:call).and_raise(
        StandardError,
        'Commission creation failed'
      )

      expect { disbursement_interactor.call }.to raise_error(StandardError)

      # Verify no disbursement was created
      expect(Disbursement.count).to eq(0)
    end

    it 'ensures atomicity - rolls back commissions if disbursement creation fails' do
      # Mock Disbursement.create! to raise an error
      allow(Disbursement).to receive(:create!).and_raise(
        ActiveRecord::RecordInvalid.new(Disbursement.new)
      )

      expect { disbursement_interactor.call }.to raise_error(ActiveRecord::RecordInvalid)

      # Verify no commissions were created
      expect(Commission.count).to eq(0)
    end
  end

  describe 'with different disbursement frequencies' do
    context 'with weekly disbursement frequency' do
      let(:merchant) do
        create(
          :merchant,
          reference: 'weekly_merchant',
          disbursement_frequency: Enums::DisbursementFrequency::Weekly.serialize
        )
      end

      it 'sets correct frequency and generates weekly reference' do
        result = disbursement_interactor.call

        expect(result.frequency).to eq(Enums::DisbursementFrequency::Weekly.serialize)

        # Expected format: W{week_number}-{merchant_reference}-{date}-{year}
        expected_reference =
          "W#{date.strftime('%W')}-#{merchant.reference}-#{date.strftime('%Y%m%d')}-#{date.year}"
        expect(result.reference).to eq(expected_reference)
      end
    end
  end

  describe 'with edge cases' do
    context 'with empty orders array' do
      let(:orders) { [] }

      it 'creates disbursement with zero amounts' do
        result = disbursement_interactor.call

        expect(result.total_gross_amount).to eq(BigDecimal('0.00'))
        expect(result.total_commission).to eq(BigDecimal('0.00'))
        expect(result.total_net_amount).to eq(BigDecimal('0.00'))
        expect(result.commissions.count).to eq(0)
      end

      it 'still generates a valid reference' do
        result = disbursement_interactor.call

        expected_reference =
          "D#{date.strftime('%d')}-#{merchant.reference}-#{date.strftime('%Y%m%d')}-#{date.year}"
        expect(result.reference).to eq(expected_reference)
      end
    end

    context 'with zero amount orders' do
      let(:orders) do
        [create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 0.00)]
      end

      it 'handles zero amounts correctly' do
        result = disbursement_interactor.call

        expect(result.total_gross_amount).to eq(BigDecimal('0.00'))
        expect(result.total_commission).to eq(BigDecimal('0.00'))
        expect(result.total_net_amount).to eq(BigDecimal('0.00'))
        expect(result.commissions.count).to eq(1)
        expect(result.commissions.first.commission_amount).to eq(BigDecimal('0.00'))
      end
    end

    context 'with very large amounts' do
      let(:orders) do
        [
          create(
            :order,
            merchant: merchant,
            merchant_reference: merchant.reference,
            amount: 999_999.99
          )
        ]
      end

      it 'handles large amounts correctly' do
        result = disbursement_interactor.call

        expect(result.total_gross_amount).to eq(BigDecimal('999999.99'))
        expect(result.total_commission).to be > 0
        expect(result.total_net_amount).to be < BigDecimal('999999.99')
        expect(result.commissions.count).to eq(1)
      end
    end
  end

  describe 'with different commission rate tiers' do
    let(:orders) do
      [
        create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 25.00), # 1.00% rate
        create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 150.00), # 0.95% rate
        create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 500.00) # 0.85% rate
      ]
    end

    it 'applies correct commission rates for each tier' do
      result = disbursement_interactor.call

      expect(result.commissions.count).to eq(3)

      # Below 50€: 1.00%
      below_50_commission = result.commissions.find { |c| c.order.amount == BigDecimal('25.00') }
      expect(below_50_commission.commission_rate).to eq(BigDecimal('0.01'))

      # Between 50€ and 300€: 0.95%
      between_50_300_commission =
        result.commissions.find { |c| c.order.amount == BigDecimal('150.00') }
      expect(between_50_300_commission.commission_rate).to eq(BigDecimal('0.0095'))

      # Above 300€: 0.85%
      above_300_commission = result.commissions.find { |c| c.order.amount == BigDecimal('500.00') }
      expect(above_300_commission.commission_rate).to eq(BigDecimal('0.0085'))
    end

    it 'calculates total amounts correctly for mixed tiers' do
      result = disbursement_interactor.call

      # Expected calculations:
      # Order 1: 25.00 * 0.01 = 0.25
      # Order 2: 150.00 * 0.0095 = 1.425, rounded to 1.43
      # Order 3: 500.00 * 0.0085 = 4.25
      # Total gross: 25.00 + 150.00 + 500.00 = 675.00
      # Total commission: 0.25 + 1.43 + 4.25 = 5.93
      # Total net: 675.00 - 5.93 = 669.07

      expect(result.total_gross_amount).to eq(BigDecimal('675.00'))
      expect(result.total_commission).to eq(BigDecimal('5.93'))
      expect(result.total_net_amount).to eq(BigDecimal('669.07'))
    end
  end
end
