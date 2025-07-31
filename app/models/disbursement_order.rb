# typed: strict

class DisbursementOrder < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :disbursement
  belongs_to :order

  # Validations
  validates :order_id,
            uniqueness: {
              scope: :disbursement_id,
              message: :already_associated_with_disbursement
            }
end
