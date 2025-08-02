class FixDisbursementOrdersOrderIdType < ActiveRecord::Migration[7.1]
  def up
    # First, drop the existing index
    if index_exists?(:disbursement_orders, :order_id)
      remove_index :disbursement_orders, :order_id
    end

    # Change the column type from uuid to string
    change_column :disbursement_orders, :order_id, :string

    # Recreate the index
    add_index :disbursement_orders, :order_id
  end

  def down
    # This is a destructive change, so we'll raise an error in down migration
    # to prevent accidental data loss
    raise ActiveRecord::IrreversibleMigration,
          'Cannot reverse order_id type change without data loss'
  end
end
