# typed: strict

module Enums
  class CommissionRates < T::Enum
    enums do
      Below50 = new(BigDecimal('0.01'))
      Between50And300 = new(BigDecimal('0.0095'))
      Above300 = new(BigDecimal('0.0085'))
    end
  end
end
