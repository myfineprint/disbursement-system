# frozen_string_literal: true

FactoryBot.define do
  factory :disbursement, class: Disbursement do
    association :merchant
    frequency { Enums::DisbursementFrequency::Daily.serialize }
    disbursement_date { Date.current }
    total_gross_amount { 100.00 }
    total_commission { 1.00 }
    total_net_amount { 99.00 }
    reference { "DISB#{SecureRandom.alphanumeric(8).upcase}" }
  end
end
