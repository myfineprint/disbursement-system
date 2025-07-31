# typed: strict

class Order < ApplicationRecord
  belongs_to :merchant,
             foreign_key: 'merchant_reference',
             primary_key: 'reference',
             inverse_of: :orders

  validates :id, presence: true, uniqueness: true
  validates :merchant_reference, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :created_at, presence: true
end
