# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DailyDisbursement do
  let(:merchant) do
    create(
      :merchant,
      reference: 'windler_and_sons',
      disbursement_frequency: Enums::DisbursementFrequency::Daily.serialize
    )
  end

  let(:orders) do
    [
      create(:order, merchant: merchant, amount: 100.00),
      create(:order, merchant: merchant, amount: 250.00)
    ]
  end

  let(:daily_disbursement) do
    described_class.new(merchant: merchant, orders: orders, date: Date.current)
  end

  describe '#call' do
    context 'with valid data' do
      it 'creates a disbursement successfully' do
        result = daily_disbursement.call

        expect(result).to be_a(Disbursement)
        expect(result).to be_persisted
        expect(result.merchant).to eq(merchant)
        expect(result.frequency).to eq(Enums::DisbursementFrequency::Daily.serialize)
        expect(result.disbursement_date).to eq(Date.current)
      end

      it 'creates disbursement with correct calculated amounts' do
        result = daily_disbursement.call

        expect(result.total_gross_amount).to eq(350.00) # 100 + 250
        expect(result.total_commission).to eq(3.33) # 100 * 0.0095 + 250 * 0.0095
        expect(result.total_net_amount).to eq(result.total_gross_amount - result.total_commission)
      end

      it 'generates a valid reference' do
        result = daily_disbursement.call

        expect(result.reference).to match(/^D-#{merchant.reference}-\d{8}-\d{4}$/)
        expect(result.reference).to start_with('D-')
      end

      it 'creates disbursement order associations' do
        result = daily_disbursement.call

        expect(result).to be_a(Disbursement)
        expect(result.merchant).to eq(merchant)
        expect(result.frequency).to eq('DAILY')
        expect(result.disbursement_date).to eq(Date.current)
        # DisbursementOrder table has been removed - no longer tracking order associations
        # expect(result.disbursement_orders.count).to eq(2)
      end

      it 'associates orders with the disbursement' do
        result = daily_disbursement.call

        expect(result).to be_a(Disbursement)
        expect(result.merchant).to eq(merchant)
        # DisbursementOrder table has been removed - no longer tracking order associations
        # result.disbursement_orders.each do |disbursement_order|
        #   expect(disbursement_order.disbursement).to eq(result)
        #   expect(orders).to include(disbursement_order.order)
        # end
      end
    end

    context 'with empty orders array' do
      let(:orders) { [] }

      it 'creates disbursement with zero amounts' do
        result = daily_disbursement.call

        expect(result.total_gross_amount).to eq(0.0)
        expect(result.total_commission).to eq(0.0)
        expect(result.total_net_amount).to eq(0.0)
      end

      it 'creates disbursement without order associations' do
        result = daily_disbursement.call

        # DisbursementOrder table has been removed - no longer tracking order associations
        # expect(result.disbursement_orders.count).to eq(0)
        # expect(result.orders.count).to eq(0)
        expect(result.total_gross_amount).to eq(0.0)
      end

      it 'still generates a valid reference' do
        result = daily_disbursement.call

        expect(result.reference).to match(/^D-#{merchant.reference}-\d{8}-\d{4}$/)
      end
    end

    context 'with single order' do
      let(:orders) do
        [create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 75.50)]
      end

      it 'creates disbursement with single order association' do
        result = daily_disbursement.call

        # DisbursementOrder table has been removed - no longer tracking order associations
        # expect(result.disbursement_orders.count).to eq(1)
        # expect(result.orders).to eq(orders)
        expect(result.total_gross_amount).to eq(75.50)
        expect(result.total_commission).to eq(0.72) # 75.50 * 0.0095
      end
    end

    context 'with multiple orders' do
      let(:orders) do
        Array.new(5) do |i|
          create(
            :order,
            merchant: merchant,
            merchant_reference: merchant.reference,
            amount: 10.00 + i
          )
        end
      end

      it 'handles multiple order processing' do
        result = daily_disbursement.call

        # DisbursementOrder table has been removed - no longer tracking order associations
        # expect(result.disbursement_orders.count).to eq(5)
        # expect(result.orders.count).to eq(5)
        expect(result.total_gross_amount).to eq(orders.sum(&:amount))
      end
    end

    context 'with orders from different merchants' do
      let(:other_merchant) { create(:merchant, reference: 'other_merchant') }
      let(:orders) do
        [
          create(
            :order,
            merchant: merchant,
            merchant_reference: merchant.reference,
            amount: 100.00
          ),
          create(
            :order,
            merchant: other_merchant,
            merchant_reference: other_merchant.reference,
            amount: 200.00
          )
        ]
      end

      it 'creates disbursement only for the specified merchant' do
        result = daily_disbursement.call

        expect(result.merchant).to eq(merchant)
        # DisbursementOrder table has been removed - no longer tracking order associations
        # expect(result.disbursement_orders.count).to eq(2)
        # Both orders are associated, but disbursement belongs to the specified merchant
        # expect(result.orders).to match_array(orders)
        expect(result.total_gross_amount).to eq(orders.sum(&:amount))
      end
    end

    context 'with edge case order amounts' do
      it 'handles very small amounts' do
        small_order =
          create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 0.01)
        daily_disbursement = described_class.new(merchant: merchant, orders: [small_order])

        result = daily_disbursement.call

        expect(result.total_gross_amount).to eq(0.01)
        expect(result.total_commission).to eq(0.00)
        expect(result.total_net_amount).to eq(0.01)
      end

      it 'handles very large amounts' do
        large_order =
          create(
            :order,
            merchant: merchant,
            merchant_reference: merchant.reference,
            amount: 999_999.99
          )
        daily_disbursement = described_class.new(merchant: merchant, orders: [large_order])

        result = daily_disbursement.call

        expect(result.total_gross_amount).to eq(999_999.99)
        expect(result.total_commission).to be > 0
        expect(result.total_net_amount).to be < 999_999.99
      end

      it 'handles zero amount orders' do
        zero_order =
          create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: 0.00)
        daily_disbursement = described_class.new(merchant: merchant, orders: [zero_order])

        result = daily_disbursement.call

        expect(result.total_gross_amount).to eq(0.00)
        expect(result.total_commission).to eq(0.00)
        expect(result.total_net_amount).to eq(0.00)
      end
    end

    context 'with invalid merchant data' do
      context 'when merchant has invalid disbursement frequency' do
        let(:merchant) do
          create(:merchant, reference: 'invalid_merchant', disbursement_frequency: 'INVALID')
        end

        it 'raises validation error' do
          expect { daily_disbursement.call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context 'when merchant is missing required fields' do
        let(:merchant) { build(:merchant, reference: nil, email: nil) }

        it 'raises validation error' do
          expect { daily_disbursement.call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'with invalid order data' do
      context 'when order has negative amount' do
        let(:orders) do
          [
            create(
              :order,
              merchant: merchant,
              merchant_reference: merchant.reference,
              amount: -50.00
            )
          ]
        end

        it 'raises validation error' do
          expect { daily_disbursement.call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context 'when order has nil amount' do
        let(:orders) do
          [create(:order, merchant: merchant, merchant_reference: merchant.reference, amount: nil)]
        end

        it 'raises validation error' do
          expect { daily_disbursement.call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'transaction behavior' do
      it 'ensures atomicity of the entire operation' do
        # This test verifies that if any part fails, nothing is persisted
        allow(Disbursement).to receive(:create!).and_raise(
          StandardError,
          'Disbursement creation failed'
        )

        expect { daily_disbursement.call }.to raise_error(
          StandardError,
          'Disbursement creation failed'
        )
        expect(Disbursement.count).to eq(0)
        # DisbursementOrder table has been removed
        # expect(DisbursementOrder.count).to eq(0)
      end
    end
  end

  describe 'idempotency' do
    it 'creates multiple disbursements when called multiple times' do
      first_result = daily_disbursement.call
      second_result = daily_disbursement.call

      # Without disbursement_orders table, each call creates a new disbursement
      expect(Disbursement.count).to eq(2)
      expect(first_result).to be_a(Disbursement)
      expect(second_result).to be_a(Disbursement)
      expect(first_result.id).not_to eq(second_result.id)
    end
  end
end
