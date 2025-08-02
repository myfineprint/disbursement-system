# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DisbursementReferenceGenerator do
  describe '.call' do
    let(:disbursement_date) { Date.new(2024, 1, 15) }

    context 'when merchant has daily disbursement frequency' do
      let(:merchant) do
        create(
          :merchant,
          reference: 'windler_and_sons',
          disbursement_frequency: Enums::DisbursementFrequency::Daily.serialize
        )
      end

      it 'generates reference with daily prefix' do
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        expect(result).to eq('D-windler_and_sons-20240115-2024')
      end

      it 'uses correct date format' do
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        # Should format date as YYYYMMDD
        expect(result).to include('20240115')
      end

      it 'includes the year from disbursement date' do
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        # Should include year at the end
        expect(result).to end_with('2024')
      end
    end

    context 'when merchant has weekly disbursement frequency' do
      let(:merchant) do
        create(
          :merchant,
          reference: 'mraz_and_sons',
          disbursement_frequency: Enums::DisbursementFrequency::Weekly.serialize
        )
      end

      it 'generates reference with weekly prefix' do
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        expect(result).to eq('W-mraz_and_sons-20240115-2024')
      end

      it 'uses correct date format' do
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        # Should format date as YYYYMMDD
        expect(result).to include('20240115')
      end

      it 'includes the year from disbursement date' do
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        # Should include year at the end
        expect(result).to end_with('2024')
      end
    end

    context 'with different date scenarios' do
      let(:merchant) do
        create(
          :merchant,
          reference: 'cummerata_llc',
          disbursement_frequency: Enums::DisbursementFrequency::Daily.serialize
        )
      end

      it 'handles single digit month and day' do
        date = Date.new(2024, 3, 5)
        result =
          described_class.call(merchant: merchant, disbursement_date: date)

        expect(result).to eq('D-cummerata_llc-20240305-2024')
      end

      it 'handles leap year dates' do
        date = Date.new(2024, 2, 29)
        result =
          described_class.call(merchant: merchant, disbursement_date: date)

        expect(result).to eq('D-cummerata_llc-20240229-2024')
      end

      it 'handles year boundary dates' do
        date = Date.new(2023, 12, 31)
        result =
          described_class.call(merchant: merchant, disbursement_date: date)

        expect(result).to eq('D-cummerata_llc-20231231-2023')
      end
    end

    context 'with different merchant references' do
      let(:merchant) do
        create(
          :merchant,
          disbursement_frequency: Enums::DisbursementFrequency::Daily.serialize
        )
      end

      it 'handles alphanumeric references' do
        merchant.update!(reference: 'ABC123XYZ')
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        expect(result).to eq('D-ABC123XYZ-20240115-2024')
      end

      it 'handles references with special characters' do
        merchant.update!(reference: 'MERCH-REF_001')
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        expect(result).to eq('D-MERCH-REF_001-20240115-2024')
      end

      it 'handles short references' do
        merchant.update!(reference: 'A')
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        expect(result).to eq('D-A-20240115-2024')
      end
    end

    context 'reference format validation' do
      let(:merchant) do
        create(
          :merchant,
          reference: 'MERCH123',
          disbursement_frequency: Enums::DisbursementFrequency::Daily.serialize
        )
      end

      it 'follows the expected format pattern' do
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        # Format: {PREFIX}-{MERCHANT_REF}-{YYYYMMDD}-{YYYY}
        expect(result).to match(/^[DW]-[^-]+-\d{8}-\d{4}$/)
      end

      it 'has correct number of components' do
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        components = result.split('-')
        expect(components.length).to eq(4)
      end

      it 'has correct component structure' do
        result =
          described_class.call(
            merchant: merchant,
            disbursement_date: disbursement_date
          )

        components = result.split('-')

        expect(components[0]).to match(/^[DW]$/) # Prefix (D or W)
        expect(components[1]).to eq(merchant.reference) # Merchant reference
        expect(components[2]).to match(/^\d{8}$/) # Date in YYYYMMDD format
        expect(components[3]).to match(/^\d{4}$/) # Year
      end
    end
  end
end
