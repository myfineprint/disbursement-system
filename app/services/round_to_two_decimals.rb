# typed: strict

class RoundToTwoDecimals
  extend T::Sig

  sig { params(value: BigDecimal).returns(BigDecimal) }
  def call(value)
    BigDecimal(value.to_s).round(2)
  end
end
