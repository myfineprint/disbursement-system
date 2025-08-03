# typed: false

FactoryBot.define do
  factory :monthly_minimum_fee_default do
    association :merchant
    minimum_monthly_fee { BigDecimal('100.00') }
    actual_commission_paid { BigDecimal('75.50') }
    defaulted_amount { minimum_monthly_fee - actual_commission_paid }
    period_date { Date.current.beginning_of_month }

    trait :with_small_default do
      minimum_monthly_fee { BigDecimal('100.00') }
      actual_commission_paid { BigDecimal('95.00') }
      defaulted_amount { BigDecimal('5.00') }
    end

    trait :with_large_default do
      minimum_monthly_fee { BigDecimal('100.00') }
      actual_commission_paid { BigDecimal('25.00') }
      defaulted_amount { BigDecimal('75.00') }
    end

    trait :with_minimum_default do
      minimum_monthly_fee { BigDecimal('100.00') }
      actual_commission_paid { BigDecimal('99.99') }
      defaulted_amount { BigDecimal('0.01') }
    end
  end
end
