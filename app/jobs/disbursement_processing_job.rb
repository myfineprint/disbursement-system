# typed: strict

class DisbursementProcessingJob < ApplicationJob
  extend T::Sig

  BATCH_SIZE = 10

  queue_as :default

  sig { params(date: T.nilable(Date)).void }
  def perform(date = Date.current)
    merchant_references = Merchant.live_as_of(date)

    merchant_references.find_each(batch_size: BATCH_SIZE) do |merchant|
      ProcessMerchantOrdersJob.perform_later(merchant:, date:)
    end
  end
end
