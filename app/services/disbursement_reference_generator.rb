# typed: strict

module DisbursementReferenceGenerator
  extend T::Sig

  sig { params(merchant: Merchant, disbursement_date: Date).returns(String) }
  def self.call(merchant:, disbursement_date:)
    day_number = disbursement_date.strftime('%d')
    week_number = disbursement_date.strftime('%W')
    prefix = merchant.daily_disbursement? ? "D#{day_number}" : "W#{week_number}"

    "#{prefix}-#{merchant.reference}-#{disbursement_date.strftime('%Y%m%d')}-#{disbursement_date.year}"
  end
end
