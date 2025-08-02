class ChangeDisbursementsToUseUuidPrimaryKey < ActiveRecord::Migration[7.1]
  def up
    # First, drop the existing index on disbursement_orders.disbursement_id
    if index_exists?(:disbursement_orders, :disbursement_id)
      remove_index :disbursement_orders, :disbursement_id
    end

    # Change disbursements.id to UUID
    change_table :disbursements do |t|
      t.remove :id
    end
    add_column :disbursements,
               :id,
               :uuid,
               default: -> { 'gen_random_uuid()' },
               null: false
    execute 'ALTER TABLE disbursements ADD PRIMARY KEY (id)'

    # Recreate the index on disbursement_orders.disbursement_id
    add_index :disbursement_orders, :disbursement_id
  end

  def down
    # This is a destructive change, so we'll raise an error in down migration
    # to prevent accidental data loss
    raise ActiveRecord::IrreversibleMigration,
          'Cannot reverse disbursements UUID primary key change without data loss'
  end
end
