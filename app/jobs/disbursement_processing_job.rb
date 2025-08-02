# typed: strict

class DisbursementProcessingJob < ApplicationJob
  extend T::Sig

  BATCH_SIZE = 100

  queue_as :default

  sig { void }
  def perform
    merchant_references = Merchant.live_as_of(Date.current).pluck(:reference)

    merchant_references.each_slice(BATCH_SIZE) do |batch|
      ProcessMerchantOrdersJob.perform_later(merchant_references: batch)
    end
  end
end
