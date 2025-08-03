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
        result = described_class.call(merchant: merchant, disbursement_date: disbursement_date)

        expect(result).to eq('D15-windler_and_sons-20240115-2024')
      end

      it 'uses correct date format' do
        result = described_class.call(merchant: merchant, disbursement_date: disbursement_date)

        # Should format date as YYYYMMDD
        expect(result).to include('20240115')
      end

      it 'includes the year from disbursement date' do
        result = described_class.call(merchant: merchant, disbursement_date: disbursement_date)

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
        result = described_class.call(merchant: merchant, disbursement_date: disbursement_date)

        expect(result).to eq('W03-mraz_and_sons-20240115-2024')
      end

      it 'uses correct date format' do
        result = described_class.call(merchant: merchant, disbursement_date: disbursement_date)

        # Should format date as YYYYMMDD
        expect(result).to include('20240115')
      end

      it 'includes the year from disbursement date' do
        result = described_class.call(merchant: merchant, disbursement_date: disbursement_date)

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
        result = described_class.call(merchant: merchant, disbursement_date: date)

        expect(result).to eq('D05-cummerata_llc-20240305-2024')
      end

      it 'handles leap year dates' do
        date = Date.new(2024, 2, 29)
        result = described_class.call(merchant: merchant, disbursement_date: date)

        expect(result).to eq('D29-cummerata_llc-20240229-2024')
      end

      it 'handles year boundary dates' do
        date = Date.new(2023, 12, 31)
        result = described_class.call(merchant: merchant, disbursement_date: date)

        expect(result).to eq('D31-cummerata_llc-20231231-2023')
      end
    end

    context 'with different merchant references' do
      let(:merchant) do
        create(:merchant, disbursement_frequency: Enums::DisbursementFrequency::Daily.serialize)
      end

      it 'handles alphanumeric references' do
        merchant.update!(reference: 'ABC123XYZ')
        result = described_class.call(merchant: merchant, disbursement_date: disbursement_date)

        expect(result).to eq('D15-ABC123XYZ-20240115-2024')
      end

      it 'handles references with special characters' do
        merchant.update!(reference: 'MERCH-REF_001')
        result = described_class.call(merchant: merchant, disbursement_date: disbursement_date)

        expect(result).to eq('D15-MERCH-REF_001-20240115-2024')
      end

      it 'handles short references' do
        merchant.update!(reference: 'A')
        result = described_class.call(merchant: merchant, disbursement_date: disbursement_date)

        expect(result).to eq('D15-A-20240115-2024')
      end
    end
  end
end
