# typed: strict

module DisbursementReferenceGenerator
  extend T::Sig

  sig { params(merchant: Merchant, disbursement_date: Date).returns(String) }
  def self.call(merchant:, disbursement_date:)
    prefix = merchant.daily_disbursement? ? 'D' : 'W'

    "#{prefix}-#{merchant.reference}-#{disbursement_date.strftime('%Y%m%d')}-#{disbursement_date.year}"
  end
end
