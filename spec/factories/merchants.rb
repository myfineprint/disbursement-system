# frozen_string_literal: true

FactoryBot.define do
  factory :merchant, class: Merchant do
    sequence(:reference) { |n| "MERCHANT#{n.to_s.rjust(3, '0')}" }
    sequence(:email) { |n| "merchant#{n}@example.com" }
    live_on { Date.current }
    disbursement_frequency { 'DAILY' }
    minimum_monthly_fee { 29.99 }
  end
end
