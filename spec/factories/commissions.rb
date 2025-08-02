# typed: false

FactoryBot.define do
  factory :commission, class: Commission do
    association :disbursement
    association :order
    commission_amount { 1.50 }
    commission_rate { 0.0095 }
  end
end
