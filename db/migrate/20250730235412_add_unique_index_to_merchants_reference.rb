class AddUniqueIndexToMerchantsReference < ActiveRecord::Migration[7.1]
  def change
    add_index :merchants, :reference, unique: true
  end
end
