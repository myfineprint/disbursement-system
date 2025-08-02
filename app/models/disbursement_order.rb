# typed: strict

class DisbursementOrder < ApplicationRecord
  extend T::Sig

  # Associations
  belongs_to :disbursement, class_name: 'Disbursement', optional: false
  belongs_to :order, class_name: 'Order', optional: false
end
