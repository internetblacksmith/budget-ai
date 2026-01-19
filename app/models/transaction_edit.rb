class TransactionEdit < ApplicationRecord
  OVERRIDABLE_FIELDS = %i[category is_transfer notes description].freeze

  validates :transaction_id, presence: true, uniqueness: { scope: :source }
  validates :source, presence: true

  def self.record_edit(transaction, attrs)
    edit = find_or_initialize_by(transaction_id: transaction.transaction_id, source: transaction.source)

    attrs.slice(*OVERRIDABLE_FIELDS).each do |field, value|
      edit[field] = value unless value.nil?
    end

    edit.save!
    edit
  end

  def self.bulk_record_edit(transactions_relation, attrs)
    transactions_relation.find_each do |transaction|
      record_edit(transaction, attrs)
    end
  end

  def self.reapply_all!
    count = 0

    find_each do |edit|
      transaction = Transaction.find_by(transaction_id: edit.transaction_id, source: edit.source)
      next unless transaction

      overrides = {}
      OVERRIDABLE_FIELDS.each do |field|
        value = edit[field]
        overrides[field] = value unless value.nil?
      end

      if overrides.any?
        transaction.update_columns(overrides)
        count += 1
      end
    end

    count
  end
end
