class CreateTransactionEdits < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_edits do |t|
      t.string :transaction_id, null: false
      t.string :source, null: false
      t.string :category
      t.boolean :is_transfer
      t.text :notes
      t.string :description
      t.timestamps
    end

    add_index :transaction_edits, [ :transaction_id, :source ], unique: true
  end
end
