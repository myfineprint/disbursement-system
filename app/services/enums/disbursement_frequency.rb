# typed: strict

module Enums
  class DisbursementFrequency < T::Enum
    extend T::Sig

    enums do
      Daily = new('DAILY')
      Weekly = new('WEEKLY')
    end

    sig { returns(T::Boolean) }
    def daily?
      self == Daily
    end

    sig { returns(T::Boolean) }
    def weekly?
      self == Weekly
    end
  end
end
