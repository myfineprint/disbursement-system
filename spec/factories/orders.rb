# frozen_string_literal: true

FactoryBot.define do
  factory :order, class: Order do
    association :merchant, factory: :merchant
    merchant_reference { merchant.reference }
    amount { 100.00 }
    created_at { Time.current }
  end
end
