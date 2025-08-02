class ChangeDisbursementsToUseUuidPrimaryKey < ActiveRecord::Migration[7.1]
  def up
    # Change disbursements.id to UUID
    change_table :disbursements do |t|
      t.remove :id
    end
    add_column :disbursements, :id, :uuid, default: -> { 'gen_random_uuid()' }, null: false
    execute 'ALTER TABLE disbursements ADD PRIMARY KEY (id)'
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'Cannot reverse disbursements UUID primary key change without data loss'
  end
end
