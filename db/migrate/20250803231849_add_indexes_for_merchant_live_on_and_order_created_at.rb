class AddIndexesForMerchantLiveOnAndOrderCreatedAt < ActiveRecord::Migration[7.1]
  def change
    add_index :merchants, :live_on
    add_index :orders, :created_at
  end
end
