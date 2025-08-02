# typed: strict

module Enums
  class CommissionRates < T::Enum
    enums do
      Below50 = new(0.01)
      Between50And300 = new(0.0095)
      Above300 = new(0.0085)
    end
  end
end
